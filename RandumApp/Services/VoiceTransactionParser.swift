//
//  VoiceTransactionParser.swift
//  RandumApp
//
//  Created by dannyduy on 27/10/26.
//

import Foundation

struct VoiceTransactionParser {
    static func parse(text: String) -> TransactionItem {
        // 1. Chuẩn hóa text ban đầu
        var normalizedText = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        normalizedText = normalizedText
            .replacingOccurrences(of: "gưỡi", with: "rưỡi")
            .replacingOccurrences(of: "tỉ", with: "tỷ")
            .replacingOccurrences(of: "ngàn", with: "nghìn")
            .replacingOccurrences(of: "củ", with: "triệu")
            .replacingOccurrences(of: "nít", with: "lít")
        
        // Gộp "3 l" hoặc "3 lít" -> thành "300k"
        normalizedText = normalizedText
            .replacingOccurrences(of: #"(\d+)\s*lít\b"#, with: "$100k", options: .regularExpression)
            .replacingOccurrences(of: #"(\d+)\s*l\b"#, with: "$100k", options: .regularExpression)
        
        normalizedText = normalizedText
            .replacingOccurrences(of: "chục", with: "0k")
            .replacingOccurrences(of: "\\bca\\b", with: "k", options: .regularExpression)
            .replacingOccurrences(of: "\\bdollars?\\b", with: "usd", options: .regularExpression)
            .replacingOccurrences(of: "\\bbucks?\\b", with: "usd", options: .regularExpression)
            .replacingOccurrences(of: "$", with: " usd ")
        
        // 2. Xác định Loại giao dịch
        let incomeKeywords = [
            "lương", "thu nhập", "thưởng", "được cho", "tiền lãi",
            "lì xì", "cho thuê", "tiền trọ nhận", "salary", "bonus", "income"
        ]
        let isIncome = incomeKeywords.contains { normalizedText.contains($0) }
        let transactionType: TransactionType = isIncome ? .income : .expense
        
        // 3. Bóc tách số tiền
        let (extractedAmount, matchedAmountString) = extractAmount(from: normalizedText)
        
        // 4. Xác định danh mục
        let category = detectCategory(from: normalizedText, isIncome: isIncome)
        
        // 5. Làm sạch Title
        var title = normalizedText
        if let matchedString = matchedAmountString, !matchedString.isEmpty {
            title = title.replacingOccurrences(of: matchedString, with: "")
        }
        
        let redundantStopWords = [
            "hết", "khoảng", "tầm", "mất", "cho", "tiền", "đã", "vừa", "mua",
            "spent", "cost", "paid", "for", "about", "around", "bought", "pay", "usd"
        ]
        for word in redundantStopWords {
            title = title.replacingOccurrences(of: "\\b\(word)\\b", with: "", options: .regularExpression)
        }
        title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if title.isEmpty {
            title = category.rawValue
        } else {
            title = title.prefix(1).uppercased() + title.dropFirst()
        }
        
        return TransactionItem(
            title: title,
            amount: extractedAmount,
            date: Date(),
            type: transactionType,
            category: category
        )
    }
    
    // MARK: - Amount Extraction
    private static func extractAmount(from text: String) -> (Double, String?) {
        var workingText = text
        
        // 1. Xử lý lỗi speech recognition với số tỷ
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
        
        // 2. Xử lý từ "rưỡi" đi kèm số định dạng
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
                    switch baseNumber {
                    case 100_000_000_000...: bonus = 50_000_000_000
                    case 1_000_000_000...:   bonus = 500_000_000
                    case 100_000_000...:     bonus = 50_000_000
                    case 1_000_000...:       bonus = 500_000
                    case 100_000...:         bonus = 50_000
                    case 1_000...:           bonus = 500
                    default:                 bonus = 0.5
                    }
                    return (baseNumber + bonus, fullMatchedString)
                }
            }
        }
        
        // 3. Xử lý đơn vị + "rưỡi" (ví dụ: 1k rưỡi, 3 triệu rưỡi)
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
                    case "tỷ":          calculatedTotal = (baseNumber + 0.5) * 1_000_000_000
                    case "triệu", "tr": calculatedTotal = (baseNumber + 0.5) * 1_000_000
                    case "trăm":        calculatedTotal = (baseNumber + 0.5) * 100_000
                    case "k", "nghìn":  calculatedTotal = (baseNumber + 0.5) * 1_000
                    default: break
                    }
                    return (calculatedTotal, fullMatchedString)
                }
            }
        }
        
        // 4. Parser số tiêu chuẩn
        let standardPattern = #"(usd\s*)?(\d+(?:[\.,]\d+)*)\s*(tỷ|triệu|tr|nghìn|trăm|k|m|b|vnd|vnđ|đ|usd)?"#
        guard let standardRegex = try? NSRegularExpression(pattern: standardPattern, options: .caseInsensitive) else {
            return (0, nil)
        }
        
        let nsString = workingText as NSString
        let matches = standardRegex.matches(in: workingText, options: [], range: NSRange(location: 0, length: nsString.length))
        
        for match in matches {
            let fullMatchedString = nsString.substring(with: match.range)
            let prefixUnit = match.range(at: 1).location != NSNotFound ? nsString.substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespaces) : ""
            var numberString = nsString.substring(with: match.range(at: 2))
            let suffixUnit = match.range(at: 3).location != NSNotFound ? nsString.substring(with: match.range(at: 3)).trimmingCharacters(in: .whitespaces) : ""
            
            let isUSD = prefixUnit.lowercased() == "usd" || suffixUnit.lowercased() == "usd"
            
            let dotParts = numberString.components(separatedBy: ".")
            let commaParts = numberString.components(separatedBy: ",")
            
            let isDotThousands = dotParts.count > 1 && dotParts.dropFirst().allSatisfy { $0.count == 3 }
            let isCommaThousands = commaParts.count > 1 && commaParts.dropFirst().allSatisfy { $0.count == 3 }
            
            if isDotThousands {
                numberString = numberString.replacingOccurrences(of: ".", with: "")
            } else if isCommaThousands {
                numberString = numberString.replacingOccurrences(of: ",", with: "")
            } else {
                numberString = numberString.replacingOccurrences(of: ",", with: ".")
            }
            
            if var baseNumber = Double(numberString) {
                if isUSD {
                    return (baseNumber, fullMatchedString)
                }
                
                switch suffixUnit {
                case "tỷ", "b":
                    baseNumber *= 1_000_000_000
                case "triệu", "tr", "m":
                    baseNumber *= 1_000_000
                case "trăm":
                    baseNumber *= 100_000
                case "k", "nghìn":
                    baseNumber *= 1_000
                default:
                    // Chỉ nhân 1.000 nếu là số trần nhỏ trong khẩu ngữ (ví dụ "ăn phở 45")
                    if baseNumber < 1000 && baseNumber > 0 {
                        baseNumber *= 1_000
                    }
                }
                // Trả về ngay khi bắt được số tiền hợp lệ đầu tiên
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
            (["ăn", "cơm", "bún", "phở", "bánh mì", "trưa", "tối", "sáng", "cà phê", "cafe", "coffee", "starbucks", "trà sữa", "nước", "food", "lunch", "dinner"], .food),
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
