//
//  ReceiptOCRParser.swift
//  RandumApp
//
//  Created by dannyduy on 28/10/26.
//

import Foundation
import CoreGraphics

// MARK: - Parse Errors
enum ReceiptParseError: LocalizedError {
    case multipleTransactionsDetected
    case noDataDetected
    
    var localizedResource: LocalizedStringResource {
        switch self {
        case .multipleTransactionsDetected:
            return "The image contains multiple transactions. Please select a single transaction detail or invoice."
        case .noDataDetected:
            return "No valid payment information found on the image."
        }
    }
    
    // Thỏa mãn giao thức LocalizedError bằng cách resolve resource ra String
    var errorDescription: String? {
        String(localized: localizedResource)
    }
}

// MARK: - Spatial Data Structures
struct OCRTextElement {
    let text: String
    let box: CGRect // Tọa độ chuẩn của Vision: (0,0) góc dưới-trái, (1,1) góc trên-phải
    
    var topDownY: CGFloat { 1.0 - box.midY } // 0.0 là Đỉnh trên cùng, 1.0 là Đáy dưới cùng
    var leftRightX: CGFloat { box.midX }     // 0.0 là Lề trái, 1.0 là Lề phải
    var textHeight: CGFloat { box.height }
}

struct OCRTextRow {
    var elements: [OCRTextElement]
    
    var topDownY: CGFloat {
        elements.map { $0.topDownY }.reduce(0, +) / CGFloat(max(1, elements.count))
    }
    
    var text: String {
        elements.map { $0.text }.joined(separator: " ")
    }
}

// MARK: - Parser Engine
struct ReceiptOCRParser {
    
    static func parse(elements: [OCRTextElement]) throws -> ParsedTransactionResult {
        guard !elements.isEmpty else {
            throw ReceiptParseError.noDataDetected
        }
        
        let rows = reconstructRows(from: elements)
        let fullLines = rows.map { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        let fullNorm = removeAccents(from: fullLines.joined(separator: " ").lowercased())
        
        // BƯỚC 1: Kiểm tra nếu có từ 2 giao dịch trở lên -> Chặn ngay lập tức!
        if isTransactionHistoryList(from: fullNorm, rows: rows, elements: elements) {
            throw ReceiptParseError.multipleTransactionsDetected
        }
        
        // BƯỚC 2: Phân loại Single Digital vs Single Physical Receipt
        let isDigitalTransaction = detectDigitalTransaction(from: fullNorm)
        
        if isDigitalTransaction {
            return parseDigitalScreen(elements: elements, rows: rows, fullLines: fullLines)
        } else {
            return parsePhysicalReceipt(rows: rows, fullLines: fullLines)
        }
    }
    
    // MARK: - Detector 1: Chặn ảnh danh sách / sao kê nhiều giao dịch
    private static func isTransactionHistoryList(from fullNorm: String, rows: [OCRTextRow], elements: [OCRTextElement]) -> Bool {
        // 1. Dấu hiệu từ khóa danh sách
        let listKeywords = [
            "giao dich gan day", "lich su giao dich", "bien dong so du",
            "tim kiem giao dich", "tat ca giao dich", "so du cuoi"
        ]
        if listKeywords.contains(where: { fullNorm.contains($0) }) {
            return true
        }
        
        // 2. Đếm số lượng mốc thời gian dạng "Thứ..., ngày...":
        // Trong ảnh Techcombank có: "Thu Ba, 20 Thg 10", "Thu Tu, 14 Thg 10"...
        let dayHeaderPatterns = [
            #"thu\s+(?:hai|ba|tu|nam|sau|bay|hai|chu nhat)"#,
            #"\d{1,2}\s+thg\s+\d{1,2}"#,
            #"thang\s+\d{1,2}\/\d{4}"#
        ]
        var dateHeaderCount = 0
        for pattern in dayHeaderPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let matches = regex.matches(in: fullNorm, options: [], range: NSRange(location: 0, length: fullNorm.utf16.count))
                dateHeaderCount += matches.count
            }
        }
        if dateHeaderCount >= 2 {
            return true
        }
        
        // 3. Đếm số lượng dòng tiền có dấu +/- (Biến động số dư Techcombank / MoMo)
        // Bắt mọi định dạng: "- 89,250", "+ 600,000", "-50.000d", "+100.000"
        var signedAmountCount = 0
        for row in rows {
            let rowText = row.text.replacingOccurrences(of: " ", with: "")
            // Bắt regex có dấu + hoặc - đi liền hoặc cách 1 khoảng với cụm số tiền
            let signedPattern = #"[+-]\s*\d{1,3}(?:[\.,]\d{3})+"#
            if let regex = try? NSRegularExpression(pattern: signedPattern) {
                let matches = regex.matches(in: rowText, options: [], range: NSRange(location: 0, length: rowText.utf16.count))
                if !matches.isEmpty {
                    signedAmountCount += 1
                }
            }
        }
        if signedAmountCount >= 2 {
            return true
        }
        
        // 4. Đếm số lần lặp lại từ khóa giao dịch ("chuyen tien", "chuyen khoan", "tien chuyen vao")
        let transferMarkers = ["chuyen tien", "chuyen khoan", "tien chuyen vao", "nap tien dien thoai"]
        var markerCount = 0
        for marker in transferMarkers {
            let occurrences = fullNorm.components(separatedBy: marker).count - 1
            markerCount += max(0, occurrences)
        }
        if markerCount >= 2 {
            return true
        }
        
        return false
    }
    
    // MARK: - Detector 2: Nhận diện Digital (MoMo / Banking) vs Receipt
    private static func detectDigitalTransaction(from fullNorm: String) -> Bool {
        if fullNorm.contains("vi momo") || fullNorm.contains("chi tiet giao dich") || fullNorm.contains("momo") {
            return true
        }
        
        let bankingKeywords = [
            "techcombank", "vietcombank", "mbbank", "vietinbank", "bidv", "vpbank", "tpbank", "acb",
            "tu tai khoan", "toi tai khoan", "chuyen tien", "loi nhan", "ma giao dich", "sao chep",
            "giao dich thanh cong", "chuyen khoan thanh cong", "nguoi nhan"
        ]
        let matchCount = bankingKeywords.filter { fullNorm.contains($0) }.count
        return matchCount >= 2
    }
    
    // MARK: ==========================================
    // MARK: CHẾ ĐỘ 1: XỬ LÝ VÍ MOMO & APP NGÂN HÀNG
    // MARK: ==========================================
    private static func parseDigitalScreen(
        elements: [OCRTextElement],
        rows: [OCRTextRow],
        fullLines: [String]
    ) -> ParsedTransactionResult {
        
        var transactionType: TransactionType = .expense
        var heroAmount: Double = 0
        var maxFontHeight: CGFloat = 0
        
        for elem in elements {
            let t = elem.text.uppercased()
            if t.contains("+") { transactionType = .income }
            if t.contains("-") { transactionType = .expense }
            
            if elem.topDownY < 0.40, let val = extractValidCurrency(from: elem.text, allowMinus: true) {
                if elem.textHeight > maxFontHeight {
                    maxFontHeight = elem.textHeight
                    heroAmount = val
                }
            }
        }
        
        let title = extractDigitalTitle(from: rows)
        let date = extractDate(from: fullLines) ?? Date()
        let category = detectDigitalCategory(from: rows, fullLines: fullLines, title: title)
        
        return ParsedTransactionResult(
            title: title,
            amount: heroAmount,
            type: transactionType,
            category: category,
            date: date
        )
    }
    
    private static func extractDigitalTitle(from rows: [OCRTextRow]) -> String {
        for row in rows where row.topDownY < 0.28 {
            let norm = removeAccents(from: row.text.lowercased())
            if norm.contains("chi tiet giao dich") || norm.contains("thanh cong") { continue }
            
            if norm.contains("chuyen den") {
                var cleanName = row.text
                    .replacingOccurrences(of: "CHUYỂN ĐẾN", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "CHUYEN DEN", with: "", options: .caseInsensitive)
                if let parenIndex = cleanName.firstIndex(of: "(") {
                    cleanName = String(cleanName[..<parenIndex])
                }
                return cleanMerchantTitle(cleanName)
            }
            
            if norm.contains("nap tien dien thoai") {
                return "Nạp Điện Thoại"
            }
            
            if norm == "grab" || norm.contains("grab") { return "Grab" }
            if norm.contains("shopee") { return "Shopee" }
            if norm.contains("lazada") { return "Lazada" }
            if norm.contains("tiktok") { return "TikTok Shop" }
        }
        
        let fieldMarkers = [
            "nguoi nhan", "nha cung cap", "dich vu", "toi tai khoan",
            "tai khoan thu huong", "ten nguoi nhan"
        ]
        
        for (idx, row) in rows.enumerated() {
            let rowNorm = removeAccents(from: row.text.lowercased())
            for marker in fieldMarkers {
                if rowNorm.contains(marker) {
                    if row.elements.count > 1, let lastElem = row.elements.last, lastElem.text != row.elements.first?.text {
                        return cleanMerchantTitle(lastElem.text)
                    }
                    if idx + 1 < rows.count {
                        return cleanMerchantTitle(rows[idx + 1].text)
                    }
                }
            }
        }
        
        return "Giao dịch MoMo"
    }
    
    private static func detectDigitalCategory(
        from rows: [OCRTextRow],
        fullLines: [String],
        title: String
    ) -> TransactionCategory {
        for (idx, row) in rows.enumerated() {
            let rowNorm = removeAccents(from: row.text.lowercased())
            if rowNorm.contains("danh muc") {
                let catText = row.text + (idx + 1 < rows.count ? " " + rows[idx + 1].text : "")
                let catNorm = removeAccents(from: catText.lowercased())
                
                if catNorm.contains("hoa don") || catNorm.contains("dien thoai") { return .bills }
                if catNorm.contains("giai tri") { return .entertainment }
                if catNorm.contains("di chuyen") { return .transport }
                if catNorm.contains("an uong") { return .food }
                if catNorm.contains("mua sam") { return .shopping }
            }
        }
        return detectCategory(from: fullLines, title: title)
    }
    
    // MARK: ==========================================
    // MARK: CHẾ ĐỘ 2: XỬ LÝ HÓA ĐƠN GIẤY 2 CỘT (Spatial 2D)
    // MARK: ==========================================
    private static func parsePhysicalReceipt(
        rows: [OCRTextRow],
        fullLines: [String]
    ) -> ParsedTransactionResult {
        let category = detectCategory(from: fullLines, title: "")
        let title = extractMerchantTitle(from: rows, fullLines: fullLines, fallbackCategory: category)
        let amount = extractTotalAmount(from: rows)
        let date = extractDate(from: fullLines) ?? Date()
        
        return ParsedTransactionResult(
            title: title,
            amount: amount,
            type: .expense,
            category: category,
            date: date
        )
    }
    
    private static func reconstructRows(from elements: [OCRTextElement]) -> [OCRTextRow] {
        let sortedTopDown = elements.sorted { $0.topDownY < $1.topDownY }
        var rowGroups: [[OCRTextElement]] = []
        
        for elem in sortedTopDown {
            if let index = rowGroups.firstIndex(where: { group in
                let avgY = group.map { $0.topDownY }.reduce(0, +) / CGFloat(group.count)
                return abs(avgY - elem.topDownY) < 0.018
            }) {
                rowGroups[index].append(elem)
            } else {
                rowGroups.append([elem])
            }
        }
        
        return rowGroups.map { group in
            OCRTextRow(elements: group.sorted { $0.leftRightX < $1.leftRightX })
        }
    }
    
    private static func extractTotalAmount(from rows: [OCRTextRow]) -> Double {
        let paymentKeywords = [
            "thanh tien", "tong tien", "tong cong", "total", "amount due",
            "vietqrpay", "zalopay", "momo", "vnpay", "tien mat", "cash", "visa", "master"
        ]
        
        for row in rows.reversed() {
            let rowNorm = removeAccents(from: row.text.lowercased())
            if isMetadataLine(rowNorm) { continue }
            
            if paymentKeywords.contains(where: { rowNorm.contains($0) }) {
                let rightNumbers = row.elements.filter { $0.leftRightX > 0.45 }
                for elem in rightNumbers.reversed() {
                    if let val = extractValidCurrency(from: elem.text, allowMinus: false) {
                        return val
                    }
                }
                for elem in row.elements.reversed() {
                    if let val = extractValidCurrency(from: elem.text, allowMinus: false) {
                        return val
                    }
                }
                if let currentRowIndex = rows.firstIndex(where: { abs($0.topDownY - row.topDownY) < 0.005 }) {
                    for offset in 1...2 {
                        let nextIndex = currentRowIndex + offset
                        if nextIndex < rows.count {
                            for elem in rows[nextIndex].elements.reversed() where elem.leftRightX > 0.45 {
                                if let val = extractValidCurrency(from: elem.text, allowMinus: false) {
                                    return val
                                }
                            }
                        }
                    }
                }
            }
        }
        
        for row in rows.reversed() where row.topDownY > 0.4 {
            let rowNorm = removeAccents(from: row.text.lowercased())
            if isMetadataLine(rowNorm) { continue }
            for elem in row.elements.reversed() where elem.leftRightX > 0.45 {
                if let val = extractValidCurrency(from: elem.text, allowMinus: false) {
                    return val
                }
            }
        }
        
        return 0
    }
    
    private static func extractValidCurrency(from text: String, allowMinus: Bool = false) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !allowMinus && trimmed.hasPrefix("-") { return nil }
        
        let cleanText = text
            .replacingOccurrences(of: "đ", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "VND", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "d", with: "", options: .caseInsensitive)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        let pattern = #"(\d{1,3}(?:[\.,]\d{3})+(?:[\.,]\d+)?|\d+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        
        let nsString = cleanText as NSString
        let matches = regex.matches(in: cleanText, options: [], range: NSRange(location: 0, length: nsString.length))
        
        for match in matches.reversed() {
            var numberString = nsString.substring(with: match.range)
            
            let dotParts = numberString.components(separatedBy: ".")
            let commaParts = numberString.components(separatedBy: ",")
            
            if dotParts.count > 1 && dotParts.dropFirst().allSatisfy({ $0.count == 3 }) {
                numberString = numberString.replacingOccurrences(of: ".", with: "")
            } else if commaParts.count > 1 && commaParts.dropFirst().allSatisfy({ $0.count == 3 }) {
                numberString = numberString.replacingOccurrences(of: ",", with: "")
            } else {
                numberString = numberString.replacingOccurrences(of: ",", with: ".")
            }
            
            let digitsOnly = numberString.filter { $0.isNumber }
            if digitsOnly.count >= 10 {
                continue
            }
            
            if let val = Double(numberString), val >= 1_000 && val <= 200_000_000 {
                return val
            }
        }
        return nil
    }
    
    private static func cleanMerchantTitle(_ rawText: String) -> String {
        let norm = removeAccents(from: rawText.lowercased())
        if norm.contains("phuc long") { return "Phúc Long" }
        if norm.contains("highlands") { return "Highlands Coffee" }
        if norm.contains("starbucks") { return "Starbucks" }
        if norm.contains("grab") { return "Grab" }
        if norm.contains("mobifone") { return "MobiFone" }
        if norm.contains("viettel") { return "Viettel" }
        if norm.contains("vinaphone") { return "VinaPhone" }
        
        let cleaned = rawText
            .replacingOccurrences(of: "CONG TY CO PHAN", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "CÔNG TY CỔ PHẦN", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "TNHH", with: "", options: .caseInsensitive)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cleaned.isEmpty ? rawText.capitalized : cleaned.capitalized
    }
    
    private static func extractMerchantTitle(
        from rows: [OCRTextRow],
        fullLines: [String],
        fallbackCategory: TransactionCategory
    ) -> String {
        let knownBrands = ["highlands": "Highlands Coffee", "phuclong": "Phúc Long", "phuc long": "Phúc Long", "starbucks": "Starbucks"]
        let topRows = rows.filter { $0.topDownY < 0.25 }
        
        for row in topRows {
            let norm = removeAccents(from: row.text.lowercased()).replacingOccurrences(of: " ", with: "")
            for (key, brand) in knownBrands {
                if norm.contains(key) { return brand }
            }
        }
        
        let addressWords = ["mai hac de", "hai ba trung", "ha noi", "ho chi minh", "duong", "quan", "tp.", "sdt", "shopid"]
        var bestCandidate: (text: String, height: CGFloat)? = nil
        for row in topRows {
            let norm = removeAccents(from: row.text.lowercased())
            if addressWords.contains(where: { norm.contains($0) }) { continue }
            if norm.contains("hoa don") || norm.contains("receipt") { continue }
            
            let avgH = row.elements.map { $0.textHeight }.reduce(0, +) / CGFloat(max(1, row.elements.count))
            if let cur = bestCandidate {
                if avgH > cur.height { bestCandidate = (row.text, avgH) }
            } else {
                bestCandidate = (row.text, avgH)
            }
        }
        
        if let candidate = bestCandidate, candidate.text.count >= 2 {
            return candidate.text.capitalized
        }
        
        switch fallbackCategory {
        case .food: return "Ăn uống"
        case .shopping: return "Mua sắm"
        default: return "Hóa đơn chi tiêu"
        }
    }
    
    private static func extractDate(from lines: [String]) -> Date? {
        let dateKeywords = ["thoi gian", "ngay", "date", "time"]
        let datePattern = #"(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{4})"#
        guard let regex = try? NSRegularExpression(pattern: datePattern) else { return nil }
        
        for line in lines {
            let norm = removeAccents(from: line.lowercased())
            if dateKeywords.contains(where: { norm.contains($0) }) {
                if let date = matchDate(in: line, regex: regex) { return date }
            }
        }
        
        for line in lines {
            let norm = removeAccents(from: line.lowercased())
            if norm.contains("diem") || norm.contains("sdt") || norm.contains("ft") { continue }
            if let date = matchDate(in: line, regex: regex) { return date }
        }
        
        return nil
    }
    
    private static func matchDate(in text: String, regex: NSRegularExpression) -> Date? {
        let nsString = text as NSString
        guard let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: nsString.length)) else {
            return nil
        }
        let dayStr = nsString.substring(with: match.range(at: 1))
        let monthStr = nsString.substring(with: match.range(at: 2))
        let yearStr = nsString.substring(with: match.range(at: 3))
        
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: "\(dayStr)/\(monthStr)/\(yearStr)")
    }
    
    private static func detectCategory(from lines: [String], title: String = "") -> TransactionCategory {
        let full = removeAccents(from: (lines.joined(separator: " ") + " " + title).lowercased())
        
        let mapping: [(keywords: [String], category: TransactionCategory)] = [
            (["highlands", "phuc long", "starbucks", "coffee", "ca phe", "cafe", "phin sua da", "tra sua", "food"], .food),
            (["winmart", "circle k", "ministop", "7-eleven", "gs25", "mart", "shopping", "shopee"], .shopping),
            (["xang", "grab", "be", "taxi", "parking", "transport", "di chuyen"], .transport),
            (["cgv", "cinema", "rap phim", "karaoke", "giai tri"], .entertainment),
            (["pharmacy", "long chau", "an khang", "benh vien"], .health),
            (["dien", "nuoc", "internet", "viettel", "mobifone", "vinaphone", "nap tien dien thoai", "bill", "hoa don"], .bills)
        ]
        
        for item in mapping {
            if item.keywords.contains(where: { full.contains($0) }) {
                return item.category
            }
        }
        return .other
    }
    
    private static func isMetadataLine(_ normLine: String) -> Bool {
        let blacklist = [
            "sdt", "tel", "hotline", "phone", "shopid", "check", "pos", "pager", "thu ngan", "wifi", "password"
        ]
        return blacklist.contains(where: { normLine.contains($0) })
    }
    
    private static func removeAccents(from string: String) -> String {
        return string
            .folding(options: .diacriticInsensitive, locale: Locale(identifier: "vi_VN"))
            .replacingOccurrences(of: "đ", with: "d")
            .replacingOccurrences(of: "Đ", with: "D")
    }
}
