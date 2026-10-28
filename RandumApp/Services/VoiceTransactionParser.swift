//
//  VoiceTransactionParser.swift
//  RandumApp
//
//  Created by dannyduy on 27/10/26.
//

import Foundation

struct VoiceTransactionParser {
    static func parse(text: String) -> ParsedTransactionResult {
        // 1. Initial normalization: lowercased, trimmed, and unified slang/pronunciation variations
        var normalizedText = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        normalizedText = normalizedText
            .replacingOccurrences(of: "gưỡi", with: "rưỡi")
            .replacingOccurrences(of: "tỉ", with: "tỷ")
            .replacingOccurrences(of: "ngàn", with: "nghìn")
            .replacingOccurrences(of: "củ", with: "triệu")
            .replacingOccurrences(of: "lít", with: "trăm")
            .replacingOccurrences(of: "l", with: "trăm")
            .replacingOccurrences(of: "chục", with: "0k")
            .replacingOccurrences(of: "\\bca\\b", with: "k", options: .regularExpression)
            .replacingOccurrences(of: "bucks", with: "dollars")
            .replacingOccurrences(of: "buck", with: "dollars")
        
        // 2. Determine transaction type (Expense / Income)
        let incomeKeywords = [
            "lương", "thu nhập", "thưởng", "được cho", "tiền lãi",
            "lì xì", "cho thuê", "tiền trọ nhận", "salary", "bonus", "income"
        ]
        let isIncome = incomeKeywords.contains { normalizedText.contains($0) }
        let transactionType: TransactionType = isIncome ? .income : .expense
        
        // 3. Extract transaction amount
        let (extractedAmount, matchedAmountString) = extractAmount(from: normalizedText)
        
        // 4. Determine category based on context keywords
        let category = detectCategory(from: normalizedText, isIncome: isIncome)
        
        // 5. Clean up title by stripping the recognized amount and filler words
        var title = normalizedText
        if let matchedString = matchedAmountString, !matchedString.isEmpty {
            title = title.replacingOccurrences(of: matchedString, with: "")
        }
        
        let redundantStopWords = [
            "hết", "khoảng", "tầm", "mất", "cho", "tiền", "đã", "vừa", "mua",
            "spent", "cost", "paid", "for", "about", "around", "bought", "pay"
        ]
        for word in redundantStopWords {
            title = title.replacingOccurrences(of: "\\b\(word)\\b", with: "", options: .regularExpression)
        }
        title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Capitalize the first letter of the cleaned title or fallback to the category name
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
        var workingText = text
        
        // 1. Resolve Apple Speech recognition glitch where billion amounts are truncated:
        // e.g., "1.000.000.0rưỡi" or "1.000.000.00rưỡi" -> normalized to "1.000.000.000rưỡi"
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
        
        // 2. Parse numbers formatted directly with the suffix "rưỡi" ("and a half"):
        // e.g., "30.000rưỡi", "300.000rưỡi", "1.000.000rưỡi", "12.000.000.000rưỡi"
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
                    
                    // Determine the fractional half addition based on numerical magnitude
                    switch baseNumber {
                    case 100_000_000_000...: // Hundreds of billions (e.g., 300B + half -> +50B)
                        bonus = 50_000_000_000
                    case 1_000_000_000...:   // Billions (e.g., 1B / 12B + half -> +500M)
                        bonus = 500_000_000
                    case 100_000_000...:     // Hundreds of millions (e.g., 300M + half -> +50M)
                        bonus = 50_000_000
                    case 1_000_000...:       // Millions (e.g., 1M + half -> +500K)
                        bonus = 500_000
                    case 100_000...:         // Hundreds of thousands (e.g., 300K + half -> +50K)
                        bonus = 50_000
                    case 1_000...:           // Thousands (e.g., 30K + half -> +500)
                        bonus = 500
                    default:
                        bonus = 0.5
                    }
                    
                    return (baseNumber + bonus, fullMatchedString)
                }
            }
        }
        
        // 3. Parse explicit unit preceding the suffix "rưỡi":
        // e.g., "1k rưỡi", "3 triệu rưỡi", "1 tỷ rưỡi", "12 tỷ rưỡi"
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
                        // e.g., 1k rưỡi = (1 + 0.5) * 1,000 = 1,500
                        calculatedTotal = (baseNumber + 0.5) * 1_000
                    default:
                        break
                    }
                    return (calculatedTotal, fullMatchedString)
                }
            }
        }
        
        // 4. Standard numerical pattern parsing: covers grouped separators (e.g., 1.000.000, 1.000.000.000) and units
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
            
            // Distinguish thousands formatting (e.g., "1.000.000") from true decimal numbers (e.g., "1.5")
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
                    // Treat small quantities without explicit currency suffix (e.g., "35", "50") as thousands
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
            // Sports & Fitness
            (["gym", "thể thao", "đá banh", "đá bóng", "cầu lông", "tennis", "pickleball", "chạy bộ", "bơi", "tiền sân", "thuê sân", "fitness", "sport", "yoga", "pilates"], .sports),
            
            // Food & Dining
            (["ăn", "cơm", "bún", "phở", "bánh mì", "trưa", "tối", "sáng", "cà phê", "cafe", "coffee", "trà sữa", "nước", "food", "lunch", "dinner"], .food),
            
            // Transportation
            (["xăng", "xe", "grab", "be", "taxi", "gửi xe", "vé xe", "bus", "transport"], .transport),
            
            // Bills & Utilities
            (["điện", "nước", "mạng", "wifi", "bill", "utilities", "tiền điện", "tiền nước"], .bills),
            
            // Housing & Rent
            (["tiền nhà", "thuê nhà", "tiền phòng", "tiền trọ", "sửa nhà", "nội thất", "rent", "housing"], .housing),
            
            // Health & Medical
            (["khám", "bệnh viện", "thuốc", "nha khoa", "bác sĩ", "medical", "pharmacy"], .health),
            
            // Education
            (["học phí", "sách", "vở", "khóa học", "course", "education", "school"], .education),
            
            // Travel & Vacation
            (["du lịch", "vé máy bay", "khách sạn", "homestay", "tour", "travel", "flight"], .travel),
            
            // Personal Care & Beauty
            (["cắt tóc", "spa", "nail", "mỹ phẩm", "skincare", "gội đầu", "barber"], .personalCare),
            
            // Shopping
            (["mua", "quần", "áo", "giày", "dép", "shopee", "lazada", "shopping", "siêu thị", "chợ"], .shopping),
            
            // Gifts & Donations
            (["đám cưới", "mừng", "sinh nhật", "quà", "từ thiện", "quyên góp", "gift"], .giftsDonations),
            
            // Entertainment
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
