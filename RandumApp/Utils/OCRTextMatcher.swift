//
//  OCRTextMatcher.swift
//  RandumApp
//
//  Created by dannyduy on 30/10/26.
//

import Foundation

struct OCRTextMatcher {
    
    // MARK: - Remove Accents (Chuẩn hóa không dấu)
    static func removeAccents(from string: String) -> String {
        return string
            .folding(options: .diacriticInsensitive, locale: Locale(identifier: "vi_VN"))
            .replacingOccurrences(of: "đ", with: "d")
            .replacingOccurrences(of: "Đ", with: "D")
    }
    
    // MARK: - Validate Currency
    static func extractCurrency(from text: String, allowMinus: Bool = false) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !allowMinus && trimmed.hasPrefix("-") { return nil }
        
        let cleanText = text
            .replacingOccurrences(of: "đ", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "VND", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "USD", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: "d", with: "", options: .caseInsensitive)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        let pattern = #"(\d{1,3}(?:[\.,]\d{3})+(?:[\.,]\d+)?|\d+(?:[\.,]\d{1,2})?)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        
        let nsString = cleanText as NSString
        let matches = regex.matches(in: cleanText, options: [], range: NSRange(location: 0, length: nsString.length))
        
        for match in matches.reversed() {
            var numberString = nsString.substring(with: match.range)
            
            let dotParts = numberString.components(separatedBy: ".")
            let commaParts = numberString.components(separatedBy: ",")
            
            // Nhận diện phân cách hàng nghìn kiểu VN (10.000) hay kiểu Mỹ (10,000.00)
            if dotParts.count > 1 && dotParts.dropFirst().allSatisfy({ $0.count == 3 }) {
                numberString = numberString.replacingOccurrences(of: ".", with: "")
            } else if commaParts.count > 1 && commaParts.dropFirst().allSatisfy({ $0.count == 3 }) {
                numberString = numberString.replacingOccurrences(of: ",", with: "")
            } else {
                // Thay dấu phẩy thập phân thành chấm
                numberString = numberString.replacingOccurrences(of: ",", with: ".")
            }
            
            let digitsOnly = numberString.filter { $0.isNumber }
            if digitsOnly.count >= 10 { continue }
            
            if let val = Double(numberString) {
                // Loại trừ năm (ví dụ 2017, 2024, 2025, 2026...) khi đứng một mình
                if val >= 2000 && val <= 2035 && !numberString.contains(".") {
                    continue
                }
                // Cho phép từ 0.5 (cho USD) đến 500,000,000 (cho VND)
                if val >= 0.5 && val <= 500_000_000 {
                    return val
                }
            }
        }
        return nil
    }
    
    // MARK: - Date Parser (EN & VI)
    static func extractDate(from lines: [String]) -> Date? {
        let dateKeywords = ["thoi gian", "ngay", "date", "time", "trans date", "created at", "check closed"]
        let datePattern = #"(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{4})"#
        guard let regex = try? NSRegularExpression(pattern: datePattern) else { return nil }
        
        // Ưu tiên dòng có chứa từ khóa liên quan đến ngày tháng
        for line in lines {
            let norm = removeAccents(from: line.lowercased())
            if dateKeywords.contains(where: { norm.contains($0) }) {
                if let date = matchDate(in: line, regex: regex) { return date }
            }
        }
        
        // Quét toàn bộ các dòng còn lại
        for line in lines {
            let norm = removeAccents(from: line.lowercased())
            if isDateNoise(norm) { continue }
            if let date = matchDate(in: line, regex: regex) { return date }
        }
        
        return nil
    }
    
    private static func matchDate(in text: String, regex: NSRegularExpression) -> Date? {
        let nsString = text as NSString
        guard let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: nsString.length)) else {
            return nil
        }
        
        let part1 = Int(nsString.substring(with: match.range(at: 1))) ?? 0
        let part2 = Int(nsString.substring(with: match.range(at: 2))) ?? 0
        let year = nsString.substring(with: match.range(at: 3))
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        // Nếu phần tử thứ 2 > 12 -> chắc chắn là MM/dd/yyyy (Ví dụ: 01/30/2017)
        if part2 > 12 && part1 <= 12 {
            formatter.dateFormat = "MM/dd/yyyy"
            return formatter.date(from: "\(part1)/\(part2)/\(year)")
        }
        
        // Mặc định thử dd/MM/yyyy trước
        formatter.dateFormat = "dd/MM/yyyy"
        if let date = formatter.date(from: "\(part1)/\(part2)/\(year)") {
            return date
        }
        
        // Fallback sang MM/dd/yyyy
        formatter.dateFormat = "MM/dd/yyyy"
        return formatter.date(from: "\(part1)/\(part2)/\(year)")
    }
    
    // MARK: - Category Detector (EN & VI)
    static func detectCategory(from lines: [String], title: String = "") -> TransactionCategory {
        let combined = lines.joined(separator: " ") + " " + title
        let full = removeAccents(from: combined.lowercased())
        
        let mapping: [(keywords: [String], category: TransactionCategory)] = [
            ([
                "highlands", "phuc long", "starbucks", "coffee", "ca phe", "cafe",
                "phin sua da", "tra sua", "food", "restaurant", "nha hang", "bakery",
                "pizza", "burger", "beverage", "milk tea", "bar", "dining"
            ], .food),
            ([
                "winmart", "circle k", "ministop", "7-eleven", "gs25", "mart",
                "shopping", "shopee", "lazada", "supermarket", "store", "mall",
                "uniqlo", "zara", "clothing", "retail"
            ], .shopping),
            ([
                "xang", "petrolimex", "pvoil", "grab", "be", "taxi", "parking",
                "transport", "di chuyen", "gasoline", "toll", "ve xe", "flight"
            ], .transport),
            ([
                "cgv", "cinema", "rap phim", "karaoke", "giai tri", "netflix",
                "spotify", "game", "entertainment", "ticket", "movie"
            ], .entertainment),
            ([
                "pharmacy", "long chau", "an khang", "benh vien", "hospital",
                "clinic", "health", "thuoc", "medical", "doctor"
            ], .health),
            ([
                "dien", "nuoc", "internet", "viettel", "mobifone", "vinaphone",
                "nap tien dien thoai", "bill", "hoa don", "utility", "top up",
                "electric", "water fee", "postpaid"
            ], .bills),
            ([
                "gym", "fitness", "yoga", "pickleball", "badminton", "sports", "workout"
            ], .sports),
            ([
                "fahasa", "nha sach", "book", "education", "course", "hoc phi", "school"
            ], .education)
        ]
        
        for item in mapping {
            if item.keywords.contains(where: { full.contains($0) }) {
                return item.category
            }
        }
        return .other
    }
    
    // MARK: - Brand Normalization
    static func cleanBrandTitle(_ rawText: String) -> String {
        let norm = removeAccents(from: rawText.lowercased())
        if norm.contains("phuc long") { return "Phúc Long" }
        if norm.contains("highlands") { return "Highlands Coffee" }
        if norm.contains("starbucks") { return "Starbucks" }
        if norm.contains("the coffee house") { return "The Coffee House" }
        if norm.contains("grab") { return "Grab" }
        if norm.contains("mobifone") { return "MobiFone" }
        if norm.contains("viettel") { return "Viettel" }
        if norm.contains("vinaphone") { return "VinaPhone" }
        if norm.contains("shopee") { return "Shopee" }
        if norm.contains("lazada") { return "Lazada" }
        if norm.contains("spotify") { return "Spotify" }
        
        let cleaned = rawText
            .replacingOccurrences(of: "CONG TY CO PHAN", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "CÔNG TY CỔ PHẦN", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "TNHH", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "JSC", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "LTD", with: "", options: .caseInsensitive)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cleaned.isEmpty ? rawText.capitalized : cleaned.capitalized
    }
    
    // MARK: - Filter Metadata & Noise
    static func isMetadataLine(_ normLine: String) -> Bool {
        let blacklist = [
            "sdt", "tel", "hotline", "phone", "shopid", "check", "pos", "pager",
            "thu ngan", "cashier", "wifi", "password", "invoice no", "receipt no",
            "vat", "mst", "tax id", "terminal"
        ]
        return blacklist.contains(where: { normLine.contains($0) })
    }
    
    private static func isDateNoise(_ normLine: String) -> Bool {
        return normLine.contains("diem") || normLine.contains("point") ||
        normLine.contains("sdt") || normLine.contains("tel") ||
        normLine.contains("ft") || normLine.contains("ref")
    }
}
