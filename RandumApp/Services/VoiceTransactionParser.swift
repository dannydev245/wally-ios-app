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
        
        // 1. Chuẩn hóa lỗi phát âm (gưỡi -> rưỡi) và các từ lóng
        workingText = workingText
            .replacingOccurrences(of: "gưỡi", with: "rưỡi")
            .replacingOccurrences(of: "tỉ", with: "tỷ")
            .replacingOccurrences(of: "ngàn", with: "nghìn")
            .replacingOccurrences(of: "củ", with: "triệu")
            .replacingOccurrences(of: "lít", with: "trăm")
            .replacingOccurrences(of: "chục", with: "0k")
        
        // 2. Fix bug riêng của Apple Speech: "1.000.000.0rưỡi" hoặc "1.000.000.00rưỡi" -> chuẩn hóa thành 1.000.000.000rưỡi
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
        
        // 3. Xử lý các số đã bị Apple format dính liền chữ rưỡi: vd "30.000rưỡi", "1.000.000rưỡi", "12.000.000.000rưỡi"
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
                    if baseNumber >= 1_000_000_000 {
                        // Cấp Tỷ: rưỡi = + 500 triệu (vd: 12 tỷ rưỡi -> 12.500.000.000)
                        bonus = 500_000_000
                    } else if baseNumber >= 1_000_000 {
                        // Cấp Triệu: rưỡi = + 500 nghìn (vd: 1 triệu rưỡi -> 1.500.000)
                        bonus = 500_000
                    } else if baseNumber >= 10_000 {
                        // Cấp Chục nghìn: rưỡi = + 5 nghìn (vd: 30 ngàn rưỡi -> 35.000)
                        bonus = 5_000
                    } else if baseNumber >= 1_000 {
                        // Cấp Nghìn: rưỡi = + 500 đồng
                        bonus = 500
                    }
                    return (baseNumber + bonus, fullMatchedString)
                }
            }
        }
        
        // 4. Case có đơn vị rõ ràng trước chữ "rưỡi": vd "3 triệu rưỡi", "1 tỷ rưỡi", "12 tỷ rưỡi"
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
        
        // 5. Case số thông thường (1.000.000.000, 1.000.000, 50k, 12 tỷ, ...)
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
