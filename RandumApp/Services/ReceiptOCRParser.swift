//
//  ReceiptOCRParser.swift
//  RandumApp
//
//  Created by dannyduy on 28/10/26.
//

import Foundation
import CoreGraphics

// MARK: - Spatial Data Structures
struct OCRTextElement {
    let text: String
    let box: CGRect // Tọa độ chuẩn của Vision: (0,0) góc dưới-trái, (1,1) góc trên-phải
    
    // Tọa độ chuẩn sau khi fixedOrientation:
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
    
    static func parse(elements: [OCRTextElement]) -> ParsedTransactionResult {
        // 1. Dựng lại các hàng ngang từ trên xuống dưới
        let rows = reconstructRows(from: elements)
        let fullLines = rows.map { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        
        let category = detectCategory(from: fullLines)
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
    
    // MARK: - 1. Spatial Row Reconstruction
    private static func reconstructRows(from elements: [OCRTextElement]) -> [OCRTextRow] {
        // Sắp xếp các từ từ đỉnh hóa đơn xuống đáy hóa đơn
        let sortedTopDown = elements.sorted { $0.topDownY < $1.topDownY }
        var rowGroups: [[OCRTextElement]] = []
        
        for elem in sortedTopDown {
            // Dung sai chênh lệch trục Y giữa các từ cùng hàng là 0.018 (~1.8% chiều cao bill)
            if let index = rowGroups.firstIndex(where: { group in
                let avgY = group.map { $0.topDownY }.reduce(0, +) / CGFloat(group.count)
                return abs(avgY - elem.topDownY) < 0.018
            }) {
                rowGroups[index].append(elem)
            } else {
                rowGroups.append([elem])
            }
        }
        
        // Trong mỗi hàng ngang, sắp xếp từ trái sang phải
        return rowGroups.map { group in
            OCRTextRow(elements: group.sorted { $0.leftRightX < $1.leftRightX })
        }
    }
    
    // MARK: - 2. Amount Extraction
    private static func extractTotalAmount(from rows: [OCRTextRow]) -> Double {
        let paymentKeywords = [
            "thanh tien", "tong tien", "tong cong", "total", "amount due",
            "vietqrpay", "zalopay", "momo", "vnpay", "tien mat", "cash", "visa", "master"
        ]
        
        // Duyệt từ dưới lên để lấy số tiền thanh toán thực tế cuối cùng
        for row in rows.reversed() {
            let rowNorm = removeAccents(from: row.text.lowercased())
            if isMetadataLine(rowNorm) { continue }
            
            if paymentKeywords.contains(where: { rowNorm.contains($0) }) {
                // Ưu tiên 1: Lấy số tiền nằm ở nửa bên phải (leftRightX > 0.45) cùng hàng này
                let rightNumbers = row.elements.filter { $0.leftRightX > 0.45 }
                for elem in rightNumbers.reversed() {
                    if let val = extractValidCurrency(from: elem.text) {
                        return val
                    }
                }
                
                // Ưu tiên 2: Tìm bất kỳ số tiền hợp lệ nào trên cùng hàng này
                for elem in row.elements.reversed() {
                    if let val = extractValidCurrency(from: elem.text) {
                        return val
                    }
                }
                
                // Ưu tiên 3: Nếu cột số tiền nằm lệch ở 1-2 dòng ngay sau
                if let currentRowIndex = rows.firstIndex(where: { abs($0.topDownY - row.topDownY) < 0.005 }) {
                    for offset in 1...2 {
                        let nextIndex = currentRowIndex + offset
                        if nextIndex < rows.count {
                            let nextRow = rows[nextIndex]
                            for elem in nextRow.elements.reversed() where elem.leftRightX > 0.45 {
                                if let val = extractValidCurrency(from: elem.text) {
                                    return val
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // Fallback: Lấy số tiền ở nửa dưới hóa đơn (topDownY > 0.4)
        for row in rows.reversed() where row.topDownY > 0.4 {
            let rowNorm = removeAccents(from: row.text.lowercased())
            if isMetadataLine(rowNorm) { continue }
            
            for elem in row.elements.reversed() where elem.leftRightX > 0.45 {
                if let val = extractValidCurrency(from: elem.text) {
                    return val
                }
            }
        }
        
        return 0
    }
    
    // MARK: - 3. Validate Currency
    private static func extractValidCurrency(from text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        // Loại bỏ các dòng ghi chú giảm giá âm: "-29.000"
        if trimmed.hasPrefix("-") { return nil }
        
        let pattern = #"(\d{1,3}(?:[\.,]\d{3})+(?:[\.,]\d+)?|\d+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        
        let nsString = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
        
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
            // Chặn số điện thoại, mã hóa đơn (>= 10 số)
            if digitsOnly.count >= 10 {
                continue
            }
            
            if let val = Double(numberString), val >= 1_000 && val <= 200_000_000 {
                return val
            }
        }
        return nil
    }
    
    // MARK: - 4. Merchant Title Extraction
    private static func extractMerchantTitle(
        from rows: [OCRTextRow],
        fullLines: [String],
        fallbackCategory: TransactionCategory
    ) -> String {
        let knownBrands: [String: String] = [
            "highlands": "Highlands Coffee",
            "phuclong": "Phúc Long",
            "phuc long": "Phúc Long",
            "starbucks": "Starbucks",
            "thecoffeehouse": "The Coffee House",
            "winmart": "WinMart",
            "circlek": "Circle K",
            "ministop": "Ministop",
            "7eleven": "7-Eleven",
            "gs25": "GS25",
            "coopmart": "Co.opmart"
        ]
        
        // 1. Kiểm tra 25% đầu hóa đơn (topDownY < 0.25)
        let topRows = rows.filter { $0.topDownY < 0.25 }
        for row in topRows {
            let norm = removeAccents(from: row.text.lowercased()).replacingOccurrences(of: " ", with: "")
            for (key, brand) in knownBrands {
                if norm.contains(key) {
                    return brand
                }
            }
        }
        
        // 2. Tìm chữ lớn nhất ở vùng đầu (loại trừ địa chỉ, sđt)
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
        
        // 3. Fallback tìm domain (vd: highlandscoffee.com.vn)
        let fullNorm = removeAccents(from: fullLines.joined(separator: " ").lowercased()).replacingOccurrences(of: " ", with: "")
        for (key, brand) in knownBrands {
            if fullNorm.contains(key) {
                return brand
            }
        }
        
        switch fallbackCategory {
        case .food: return "Ăn uống"
        case .shopping: return "Mua sắm"
        default: return "Hóa đơn chi tiêu"
        }
    }
    
    // MARK: - 5. Date Extraction
    private static func extractDate(from lines: [String]) -> Date? {
        let dateKeywords = ["ngay", "date", "thoi gian", "time"]
        let datePattern = #"(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{4})"#
        guard let regex = try? NSRegularExpression(pattern: datePattern) else { return nil }
        
        for line in lines {
            let norm = removeAccents(from: line.lowercased())
            if dateKeywords.contains(where: { norm.contains($0) }) {
                if let date = matchDate(in: line, regex: regex) {
                    return date
                }
            }
        }
        
        for line in lines {
            let norm = removeAccents(from: line.lowercased())
            if norm.contains("diem") || norm.contains("sdt") { continue }
            if let date = matchDate(in: line, regex: regex) {
                return date
            }
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
    
    // MARK: - 6. Category Detection
    private static func detectCategory(from lines: [String]) -> TransactionCategory {
        let full = removeAccents(from: lines.joined(separator: " ").lowercased())
        
        let mapping: [(keywords: [String], category: TransactionCategory)] = [
            (["highlands", "phuc long", "starbucks", "coffee", "ca phe", "cafe", "phin sua da", "tra sua", "food"], .food),
            (["winmart", "circle k", "ministop", "7-eleven", "gs25", "mart", "shopping"], .shopping),
            (["xang", "grab", "be", "taxi", "parking"], .transport),
            (["cgv", "cinema", "rap phim", "karaoke"], .entertainment),
            (["pharmacy", "long chau", "an khang", "benh vien"], .health),
            (["dien", "nuoc", "internet", "viettel", "bill"], .bills)
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
            "sdt", "tel", "hotline", "phone", "shopid", "check",
            "pos", "pager", "thu ngan", "wifi", "password"
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
