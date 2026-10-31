//
//  ReceiptOCRParser.swift
//  RandumApp
//
//  Created by dannyduy on 28/10/26.
//

import Foundation
import CoreGraphics

struct ReceiptOCRParser {
    // MARK: - 1. PARSE
    static func parse(elements: [OCRTextElement]) throws -> TransactionItem {
        guard !elements.isEmpty else {
            throw ReceiptParseError.noDataDetected
        }
        
        let rows = reconstructRows(from: elements)
        let fullLines = rows.map { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        let fullNorm = OCRTextMatcher.removeAccents(from: fullLines.joined(separator: " ").lowercased())
        
        // 1.1 Block images of transaction lists/statements
        if isTransactionHistoryList(from: fullNorm, rows: rows, elements: elements) {
            throw ReceiptParseError.multipleTransactionsDetected
        }
        
        // 1.2 Identifying layout types and coordinating via switch-case
        let layoutType = resolveLayoutType(from: fullNorm)
        
        switch layoutType {
        case .digitalScreen:
            return parseDigitalScreen(elements: elements, rows: rows, fullLines: fullLines)
            
        case .physicalReceipt:
            return parsePhysicalReceipt(rows: rows, fullLines: fullLines)
        }
    }
    
    // MARK: - 2. EXECUTION PIPELINES
    /// Flow A: E-wallet (MoMo, ZaloPay) & Banking (VCB, TCB, MB, ACB...) interface
    private static func parseDigitalScreen(
        elements: [OCRTextElement],
        rows: [OCRTextRow],
        fullLines: [String]
    ) -> TransactionItem {
        
        var transactionType: TransactionType = .expense
        var heroAmount: Double = 0
        var maxFontHeight: CGFloat = 0
        
        for elem in elements {
            let t = elem.text.uppercased()
            if t.contains("+") { transactionType = .income }
            if t.contains("-") { transactionType = .expense }
            
            // Find the Hero Amount (the largest text in the upper half, where topDownY < 0.40)
            if elem.topDownY < 0.40, let val = OCRTextMatcher.extractCurrency(from: elem.text, allowMinus: true) {
                if elem.textHeight > maxFontHeight {
                    maxFontHeight = elem.textHeight
                    heroAmount = val
                }
            }
        }
        
        let title = extractDigitalTitle(from: rows)
        let date = OCRTextMatcher.extractDate(from: fullLines) ?? Date()
        let category = extractDigitalCategory(from: rows, fullLines: fullLines, title: title)
        
        return TransactionItem(
            title: title,
            amount: heroAmount,
            date: date,
            type: transactionType,
            category: category
        )
    }
    
    /// Flow B: 2-Column Paper Invoices (Spatial Clustering & Horizontal Ray-casting)
    private static func parsePhysicalReceipt(
        rows: [OCRTextRow],
        fullLines: [String]
    ) -> TransactionItem {
        let category = OCRTextMatcher.detectCategory(from: fullLines, title: "")
        let title = extractReceiptTitle(from: rows, fullLines: fullLines, fallbackCategory: category)
        let amount = extractReceiptAmount(from: rows)
        let date = OCRTextMatcher.extractDate(from: fullLines) ?? Date()
        
        return TransactionItem(
            title: title,
            amount: amount,
            date: date,
            type: .expense,
            category: category
        )
    }
    
    // MARK: - 3. DETECTORS
    private static func resolveLayoutType(from fullNorm: String) -> ReceiptLayoutType {
        let digitalKeywords = [
            // VI
            "vi momo", "chi tiet giao dich", "momo", "chuyen tien", "chuyen khoan thanh cong",
            "giao dich thanh cong", "tu tai khoan", "toi tai khoan", "tai khoan thu huong",
            "nguoi nhan", "ngan hang", "loi nhan", "ma giao dich", "sao chep",
            "techcombank", "vietcombank", "mbbank", "vietinbank", "bidv", "vpbank", "tpbank", "acb",
            // EN
            "transfer successful", "transaction details", "successful", "payment details",
            "recipient", "account number", "reference no", "transaction id"
        ]
        
        let matchCount = digitalKeywords.filter { fullNorm.contains($0) }.count
        return (matchCount >= 2 || fullNorm.contains("vi momo") || fullNorm.contains("chi tiet giao dich"))
            ? .digitalScreen
            : .physicalReceipt
    }
    
    private static func isTransactionHistoryList(from fullNorm: String, rows: [OCRTextRow], elements: [OCRTextElement]) -> Bool {
        // 1. List screen keywords
        let listKeywords = [
            "giao dich gan day", "lich su giao dich", "bien dong so du",
            "tim kiem giao dich", "tat ca giao dich", "so du cuoi",
            "recent transactions", "transaction history", "account statement", "activity"
        ]
        if listKeywords.contains(where: { fullNorm.contains($0) }) {
            return true
        }
        
        // 2. Count the days of the week (Tuesday, Wednesday... / Monday, Tuesday...)
        let dayHeaderPatterns = [
            #"thu\s+(?:hai|ba|tu|nam|sau|bay|chu nhat)"#,
            #"(?:monday|tuesday|wednesday|thursday|friday|saturday|sunday)"#,
            #"\d{1,2}\s+(?:thg|thang|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s+\d{1,2}"#,
            #"thang\s+\d{1,2}\/\d{4}"#
        ]
        var dateHeaderCount = 0
        for pattern in dayHeaderPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let matches = regex.matches(in: fullNorm, options: [], range: NSRange(location: 0, length: fullNorm.utf16.count))
                dateHeaderCount += matches.count
            }
        }
        if dateHeaderCount >= 2 { return true }
        
        // 3. Count the number of cash flows with a +/- sign
        var signedAmountCount = 0
        for row in rows {
            let rowText = row.text.replacingOccurrences(of: " ", with: "")
            let signedPattern = #"[+-]\s*\d{1,3}(?:[\.,]\d{3})+"#
            if let regex = try? NSRegularExpression(pattern: signedPattern) {
                let matches = regex.matches(in: rowText, options: [], range: NSRange(location: 0, length: rowText.utf16.count))
                if !matches.isEmpty { signedAmountCount += 1 }
            }
        }
        if signedAmountCount >= 2 { return true }
        
        // 4. Count the number of occurrences of transactional keywords
        let transferMarkers = ["chuyen tien", "chuyen khoan", "tien chuyen vao", "nap tien dien thoai", "transfer", "payment"]
        var markerCount = 0
        for marker in transferMarkers {
            let occurrences = fullNorm.components(separatedBy: marker).count - 1
            markerCount += max(0, occurrences)
        }
        return markerCount >= 2
    }
    
    // MARK: - 4. SUB-EXTRACTORS
    private static func extractDigitalTitle(from rows: [OCRTextRow]) -> String {
        for row in rows where row.topDownY < 0.28 {
            let norm = OCRTextMatcher.removeAccents(from: row.text.lowercased())
            if norm.contains("chi tiet giao dich") || norm.contains("thanh cong") || norm.contains("successful") { continue }
            
            if norm.contains("chuyen den") || norm.contains("transfer to") {
                var cleanName = row.text
                    .replacingOccurrences(of: "CHUYỂN ĐẾN", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "CHUYEN DEN", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "TRANSFER TO", with: "", options: .caseInsensitive)
                if let parenIndex = cleanName.firstIndex(of: "(") {
                    cleanName = String(cleanName[..<parenIndex])
                }
                return OCRTextMatcher.cleanBrandTitle(cleanName)
            }
            
            if norm.contains("nap tien dien thoai") || norm.contains("mobile topup") {
                return "Nạp Điện Thoại"
            }
            
            if norm == "grab" || norm.contains("grab") { return "Grab" }
            if norm.contains("shopee") { return "Shopee" }
            if norm.contains("lazada") { return "Lazada" }
            if norm.contains("tiktok") { return "TikTok Shop" }
        }
        
        let fieldMarkers = [
            "nguoi nhan", "recipient", "nha cung cap", "supplier", "provider",
            "dich vu", "service", "toi tai khoan", "tai khoan thu huong", "ten nguoi nhan"
        ]
        
        for (idx, row) in rows.enumerated() {
            let rowNorm = OCRTextMatcher.removeAccents(from: row.text.lowercased())
            for marker in fieldMarkers {
                if rowNorm.contains(marker) {
                    if row.elements.count > 1, let lastElem = row.elements.last, lastElem.text != row.elements.first?.text {
                        return OCRTextMatcher.cleanBrandTitle(lastElem.text)
                    }
                    if idx + 1 < rows.count {
                        return OCRTextMatcher.cleanBrandTitle(rows[idx + 1].text)
                    }
                }
            }
        }
        return "Giao dịch trực tuyến"
    }
    
    private static func extractDigitalCategory(from rows: [OCRTextRow], fullLines: [String], title: String) -> TransactionCategory {
        for (idx, row) in rows.enumerated() {
            let rowNorm = OCRTextMatcher.removeAccents(from: row.text.lowercased())
            if rowNorm.contains("danh muc") || rowNorm.contains("category") {
                let catText = row.text + (idx + 1 < rows.count ? " " + rows[idx + 1].text : "")
                let catNorm = OCRTextMatcher.removeAccents(from: catText.lowercased())
                
                if catNorm.contains("hoa don") || catNorm.contains("bills") || catNorm.contains("utilities") { return .bills }
                if catNorm.contains("giai tri") || catNorm.contains("entertainment") { return .entertainment }
                if catNorm.contains("di chuyen") || catNorm.contains("transport") { return .transport }
                if catNorm.contains("an uong") || catNorm.contains("food") || catNorm.contains("dining") { return .food }
                if catNorm.contains("mua sam") || catNorm.contains("shopping") { return .shopping }
            }
        }
        return OCRTextMatcher.detectCategory(from: fullLines, title: title)
    }
    
    private static func extractReceiptAmount(from rows: [OCRTextRow]) -> Double {
        let paymentKeywords = [
            // VI
            "thanh tien", "tong tien", "tong cong", "tien mat", "chuyen khoan", "vietqrpay", "zalopay", "momo", "vnpay",
            // EN
            "total", "amount due", "grand total", "net amount", "balance due", "cash", "visa", "mastercard"
        ]
        
        for row in rows.reversed() {
            let rowNorm = OCRTextMatcher.removeAccents(from: row.text.lowercased())
            if OCRTextMatcher.isMetadataLine(rowNorm) { continue }
            
            if paymentKeywords.contains(where: { rowNorm.contains($0) }) {
                let rightNumbers = row.elements.filter { $0.leftRightX > 0.45 }
                for elem in rightNumbers.reversed() {
                    if let val = OCRTextMatcher.extractCurrency(from: elem.text, allowMinus: false) {
                        return val
                    }
                }
                for elem in row.elements.reversed() {
                    if let val = OCRTextMatcher.extractCurrency(from: elem.text, allowMinus: false) {
                        return val
                    }
                }
                if let currentRowIndex = rows.firstIndex(where: { abs($0.topDownY - row.topDownY) < 0.005 }) {
                    for offset in 1...2 {
                        let nextIndex = currentRowIndex + offset
                        if nextIndex < rows.count {
                            for elem in rows[nextIndex].elements.reversed() where elem.leftRightX > 0.45 {
                                if let val = OCRTextMatcher.extractCurrency(from: elem.text, allowMinus: false) {
                                    return val
                                }
                            }
                        }
                    }
                }
            }
        }
        
        for row in rows.reversed() where row.topDownY > 0.4 {
            let rowNorm = OCRTextMatcher.removeAccents(from: row.text.lowercased())
            if OCRTextMatcher.isMetadataLine(rowNorm) { continue }
            for elem in row.elements.reversed() where elem.leftRightX > 0.45 {
                if let val = OCRTextMatcher.extractCurrency(from: elem.text, allowMinus: false) {
                    return val
                }
            }
        }
        return 0
    }
    
    private static func extractReceiptTitle(from rows: [OCRTextRow], fullLines: [String], fallbackCategory: TransactionCategory) -> String {
        let knownBrands = ["highlands": "Highlands Coffee", "phuclong": "Phúc Long", "phuc long": "Phúc Long", "starbucks": "Starbucks"]
        let topRows = rows.filter { $0.topDownY < 0.25 }
        
        for row in topRows {
            let norm = OCRTextMatcher.removeAccents(from: row.text.lowercased()).replacingOccurrences(of: " ", with: "")
            for (key, brand) in knownBrands {
                if norm.contains(key) { return brand }
            }
        }
        
        let addressWords = ["mai hac de", "hai ba trung", "ha noi", "ho chi minh", "duong", "quan", "tp.", "sdt", "shopid", "street", "road", "district"]
        var bestCandidate: (text: String, height: CGFloat)? = nil
        for row in topRows {
            let norm = OCRTextMatcher.removeAccents(from: row.text.lowercased())
            if addressWords.contains(where: { norm.contains($0) }) { continue }
            if norm.contains("hoa don") || norm.contains("receipt") || norm.contains("tax invoice") { continue }
            
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
    
    // MARK: - 5. SPATIAL RECONSTRUCTION
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
}
