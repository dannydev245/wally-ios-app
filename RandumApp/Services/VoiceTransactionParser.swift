//
//  VoiceTransactionParser.swift
//  RandumApp
//
//  Created by dannyduy on 27/10/26.
//

import Foundation

struct VoiceTransactionParser {
    static func parse(text: String) -> ParsedTransactionResult {
        let normalizedText = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 1. Determine transaction type (Expense / Income)
        let incomeKeywords = [
            "lương", "thu nhập", "thưởng", "được cho", "tiền lãi",
            "lì xì", "cho thuê", "tiền trọ nhận", "salary", "bonus", "income"
        ]
        let isIncome = incomeKeywords.contains { normalizedText.contains($0) }
        let transactionType: TransactionType = isIncome ? .income : .expense
        
        // 2. Extract amount
        let (extractedAmount, matchedAmountString) = extractAmount(from: normalizedText)
        
        // 3. Determine category
        let category = detectCategory(from: normalizedText, isIncome: isIncome)
        
        // 4. Extract and clean transaction title
        var title = normalizedText
        if let matchedString = matchedAmountString, !matchedString.isEmpty {
            title = title.replacingOccurrences(of: matchedString, with: "")
        }
        
        let redundantStopWords = ["hết", "khoảng", "tầm", "mất", "cho", "tiền", "đã", "vừa"]
        for word in redundantStopWords {
            title = title.replacingOccurrences(of: "\\b\(word)\\b", with: "", options: .regularExpression)
        }
        title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if title.isEmpty {
            title = category.rawValue
        } else {
            title = title.prefix(1).uppercased() + title.dropFirst()
        }
        
        return ParsedTransactionResult(
            title: title,
            amount: extractedAmount,
            type: transactionType,
            category: category,
            date: Date()
        )
    }
    
    // MARK: - Amount Extraction
    private static func extractAmount(from text: String) -> (Double, String?) {
        var workingText = text.lowercased()
        
        // 1. Correcting pronunciation errors (e.g., "gưỡi" to "rưỡi") and slang terms
        workingText = workingText
            .replacingOccurrences(of: "gưỡi", with: "rưỡi")
            .replacingOccurrences(of: "tỉ", with: "tỷ")
            .replacingOccurrences(of: "ngàn", with: "nghìn")
            .replacingOccurrences(of: "củ", with: "triệu")
            .replacingOccurrences(of: "lít", with: "trăm")
            .replacingOccurrences(of: "chục", with: "0k")
            .replacingOccurrences(of: "\\bca\\b", with: "k", options: .regularExpression)
        
        // 2. Fix an Apple Speech-specific bug: "1.000.000.0rưỡi" or "1.000.000.00rưỡi" -> normalized to 1.000.000.000rưỡi
        let appleBillionGlitchPattern = #"(\d+[\.,]\d{3}[\.,]\d{3}[\.,])0{1,2}rưỡi"#
        if let glitchRegex = try? NSRegularExpression(pattern: appleBillionGlitchPattern) {
            let nsString = workingText as NSString
            workingText = glitchRegex.stringByReplacingMatches(
                in: workingText,
                options: [],
                range: NSRange(location: 0, length: nsString.length),
                withTemplate: "$1000rưỡi"
            )
        }
        
        // 3. Handle numerical values ​​that have been formatted by Apple with the term "rưỡi" (meaning "and a half") appended directly to them—for example: "30.000rưỡi", "1.000.000rưỡi", and "12.000.000.000rưỡi".
        let formattedRuoiPattern = #"(\d+(?:[\.,]\d{1,3})+)\s*rưỡi"#
        if let regex = try? NSRegularExpression(pattern: formattedRuoiPattern) {
            let nsString = workingText as NSString
            if let match = regex.firstMatch(in: workingText, options: [], range: NSRange(location: 0, length: nsString.length)) {
                let fullMatchedString = nsString.substring(with: match.range)
                let rawNumberStr = nsString.substring(with: match.range(at: 1))
                    .replacingOccurrences(of: ".", with: "")
                    .replacingOccurrences(of: ",", with: "")
                
                if let baseNumber = Double(rawNumberStr) {
                    var bonus: Double = 0
                    
                    // Find the next smallest base unit to halve (0.5)
                    // Examples:
                    // 300,000,000 (Hundreds of millions) -> bonus = 50,000,000
                    // 1,000,000   (Millions)            -> bonus = 500,000
                    // 300,000     (Hundreds of thousands) -> bonus = 50,000
                    // 30,000      (Thousands)   ​​        -> bonus = 500
                    
                    switch baseNumber {
                    case 100_000_000_000...: // Trăm tỷ trở lên
                        bonus = 50_000_000_000
                    case 1_000_000_000...:   // Hàng Tỷ (1 tỷ rưỡi -> 1.5 tỷ)
                        bonus = 500_000_000
                    case 100_000_000...:     // Trăm Triệu (300 triệu rưỡi -> 350 triệu)
                        bonus = 50_000_000
                    case 1_000_000...:       // Triệu (1 triệu rưỡi, 12 triệu rưỡi)
                        bonus = 500_000
                    case 100_000...:         // Trăm Nghìn (300k rưỡi -> 350k)
                        bonus = 50_000
                    case 1_000...:           // Nghìn (30k rưỡi -> 30.500)
                        bonus = 500
                    default:
                        bonus = 0.5
                    }
                    
                    return (baseNumber + bonus, fullMatchedString)
                }
            }
        }
        
        // 4. Cases where a specific unit precedes the term "rưỡi" (half): e.g., "3 million and a half," "1 billion and a half," "12 billion and a half."
        let unitRuoiPattern = #"(\d+(?:[\.,]\d+)?)\s*(tỷ|triệu|tr|trăm|k|nghìn)\s*rưỡi"#
        if let regex = try? NSRegularExpression(pattern: unitRuoiPattern) {
            let nsString = workingText as NSString
            if let match = regex.firstMatch(in: workingText, options: [], range: NSRange(location: 0, length: nsString.length)) {
                let fullMatchedString = nsString.substring(with: match.range)
                let numberString = nsString.substring(with: match.range(at: 1)).replacingOccurrences(of: ",", with: ".")
                let unitString = nsString.substring(with: match.range(at: 2))
                
                if let baseNumber = Double(numberString) {
                    var calculatedTotal = baseNumber
                    switch unitString {
                    case "tỷ":
                        calculatedTotal = (baseNumber + 0.5) * 1_000_000_000
                    case "triệu", "tr":
                        calculatedTotal = (baseNumber + 0.5) * 1_000_000
                    case "trăm":
                        calculatedTotal = (baseNumber + 0.5) * 100_000
                    case "k", "nghìn":
                        calculatedTotal = (baseNumber + 0.5) * 1_000
                    default:
                        break
                    }
                    return (calculatedTotal, fullMatchedString)
                }
            }
        }
        
        // 5. Standard numerical formats (1.000.000.000, 1.000.000, 50k, 12 tỷ, ...)
        let standardPattern = #"(\d+(?:[\.,]\d+)*)\s*(tỷ|triệu|tr|nghìn|trăm|k|m|b|vnd|vnđ|đ)?"#
        guard let standardRegex = try? NSRegularExpression(pattern: standardPattern) else {
            return (0, nil)
        }
        
        let nsString = workingText as NSString
        let matches = standardRegex.matches(in: workingText, options: [], range: NSRange(location: 0, length: nsString.length))
        
        for match in matches {
            let fullMatchedString = nsString.substring(with: match.range)
            var numberString = nsString.substring(with: match.range(at: 1))
            let unitString = match.range(at: 2).location != NSNotFound ? nsString.substring(with: match.range(at: 2)) : ""
            
            let dotParts = numberString.components(separatedBy: ".")
            let commaParts = numberString.components(separatedBy: ",")
            
            let isDotFormatted = dotParts.count > 1 && dotParts.dropFirst().allSatisfy { $0.count == 3 }
            let isCommaFormatted = commaParts.count > 1 && commaParts.dropFirst().allSatisfy { $0.count == 3 }
            
            if isDotFormatted {
                numberString = numberString.replacingOccurrences(of: ".", with: "")
            } else if isCommaFormatted {
                numberString = numberString.replacingOccurrences(of: ",", with: "")
            } else {
                numberString = numberString.replacingOccurrences(of: ",", with: ".")
            }
            
            if var baseNumber = Double(numberString) {
                switch unitString {
                case "tỷ", "b":
                    baseNumber *= 1_000_000_000
                case "triệu", "tr", "m":
                    baseNumber *= 1_000_000
                case "trăm":
                    baseNumber *= 100_000
                case "k", "nghìn":
                    baseNumber *= 1_000
                default:
                    if baseNumber < 1000 && baseNumber > 0 {
                        baseNumber *= 1_000
                    }
                }
                return (baseNumber, fullMatchedString)
            }
        }
        
        return (0, nil)
    }
    
    // MARK: - Category Detection
    private static func detectCategory(from text: String, isIncome: Bool) -> TransactionCategory {
        if isIncome {
            let incomeMapping: [(keywords: [String], category: TransactionCategory)] = [
                (["thưởng", "bonus"], .bonus),
                (["lãi", "đầu tư", "cổ phiếu", "crypto", "dividend", "investment"], .investment),
                (["freelance", "dự án", "làm thêm", "job ngoài", "side hustle"], .freelance),
                (["cho thuê", "tiền nhà nhận", "rental"], .rentalIncome),
                (["bố mẹ cho", "lì xì", "được cho", "tặng", "allowance"], .allowance),
                (["lương", "salary"], .salary)
            ]
            
            for mapping in incomeMapping {
                if mapping.keywords.contains(where: { text.contains($0) }) {
                    return mapping.category
                }
            }
            return .salary
        }
        
        let expenseMapping: [(keywords: [String], category: TransactionCategory)] = [
            (["gym", "thể thao", "đá banh", "đá bóng", "cầu lông", "tennis", "pickleball", "chạy bộ", "bơi", "tiền sân", "thuê sân", "fitness", "sport", "yoga", "pilates"], .sports),
            (["ăn", "cơm", "bún", "phở", "bánh mì", "trưa", "tối", "sáng", "cà phê", "cafe", "coffee", "trà sữa", "nước", "food", "lunch", "dinner"], .food),
            (["xăng", "xe", "grab", "be", "taxi", "gửi xe", "vé xe", "bus", "transport"], .transport),
            (["điện", "nước", "mạng", "wifi", "bill", "utilities", "tiền điện", "tiền nước"], .bills),
            (["tiền nhà", "thuê nhà", "tiền phòng", "tiền trọ", "sửa nhà", "nội thất", "rent", "housing"], .housing),
            (["khám", "bệnh viện", "thuốc", "nha khoa", "bác sĩ", "medical", "pharmacy"], .health),
            (["học phí", "sách", "vở", "khóa học", "course", "education", "school"], .education),
            (["du lịch", "vé máy bay", "khách sạn", "homestay", "tour", "travel", "flight"], .travel),
            (["cắt tóc", "spa", "nail", "mỹ phẩm", "skincare", "gội đầu", "barber"], .personalCare),
            (["mua", "quần", "áo", "giày", "dép", "shopee", "lazada", "shopping", "siêu thị", "chợ"], .shopping),
            (["đám cưới", "mừng", "sinh nhật", "quà", "từ thiện", "quyên góp", "gift"], .giftsDonations),
            (["xem phim", "game", "chơi", "karaoke", "bar", "pub", "billiards", "bida", "entertainment"], .entertainment)
        ]
        
        for mapping in expenseMapping {
            if mapping.keywords.contains(where: { text.contains($0) }) {
                return mapping.category
            }
        }
        
        return .other
    }
}
