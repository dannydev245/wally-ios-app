//
//  ReceiptOCRParser.swift
//  RandumApp
//
//  Created by dannyduy on 28/10/26.
//

import Foundation

struct ReceiptOCRParser {
    
    /// Parses an array of recognized text lines from Vision OCR into a transaction result
    static func parse(recognizedLines: [String]) -> ParsedTransactionResult {
        let cleanedLines = recognizedLines
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        let amount = extractTotalAmount(from: cleanedLines)
        let title = extractMerchantTitle(from: cleanedLines)
        let category = detectCategory(from: cleanedLines, title: title)
        let date = extractDate(from: cleanedLines) ?? Date()
        
        return ParsedTransactionResult(
            title: title,
            amount: amount,
            type: .expense,
            category: category,
            date: date
        )
    }
    
    // MARK: - Amount Extraction
    private static func extractTotalAmount(from lines: [String]) -> Double {
        // Priority 1: Target anchor keywords indicating total amounts
        let totalKeywords = [
            "tổng cộng", "tong cong", "thanh toán", "thanh toan", "tổng tiền",
            "tong tien", "thành tiền", "thanh tien", "cần thanh toán", "tong", "tổng",
            "total", "amount due", "grand total", "balance due", "net amount", "total due"
        ]
        
        // Scan backwards as totals typically sit at the bottom of receipts
        for (index, line) in lines.enumerated().reversed() {
            let lowerLine = line.lowercased()
            if totalKeywords.contains(where: { lowerLine.contains($0) }) {
                // Try extracting amount on the same line
                if let amount = extractNumber(from: line), amount > 0 {
                    return amount
                }
                
                // If not inline, look ahead to the next 2 lines
                for offset in 1...2 {
                    let nextIndex = index + offset
                    if nextIndex < lines.count {
                        if let amount = extractNumber(from: lines[nextIndex]), amount > 0 {
                            return amount
                        }
                    }
                }
            }
        }
        
        // Priority 2: Fallback to largest detected valid currency value
        var maxAmount: Double = 0
        for line in lines {
            if let amount = extractNumber(from: line) {
                // Exclude likely phone numbers, tax IDs, or barcodes
                if amount > maxAmount && amount < 100_000_000_000 {
                    let clean = line.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
                    // Skip 10-digit phone number patterns starting with 0
                    if !(clean.count == 10 && clean.hasPrefix("0")) {
                        maxAmount = amount
                    }
                }
            }
        }
        
        return maxAmount
    }
    
    private static func extractNumber(from text: String) -> Double? {
        // Matches numerical sequences with comma/period thousands or decimal separators
        let pattern = #"(\d{1,3}(?:[\.,]\d{3})+(?:[\.,]\d+)?|\d+(?:[\.,]\d+)?)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        
        let nsString = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
        
        for match in matches.reversed() {
            var numberString = nsString.substring(with: match.range)
            
            // Normalize thousands formatting: "45.000" or "45,000"
            let dotParts = numberString.components(separatedBy: ".")
            let commaParts = numberString.components(separatedBy: ",")
            
            if dotParts.count > 1 && dotParts.dropFirst().allSatisfy({ $0.count == 3 }) {
                numberString = numberString.replacingOccurrences(of: ".", with: "")
            } else if commaParts.count > 1 && commaParts.dropFirst().allSatisfy({ $0.count == 3 }) {
                numberString = numberString.replacingOccurrences(of: ",", with: "")
            } else {
                numberString = numberString.replacingOccurrences(of: ",", with: ".")
            }
            
            if let val = Double(numberString), val > 0 {
                return val
            }
        }
        return nil
    }
    
    // MARK: - Title / Merchant Extraction
    private static func extractMerchantTitle(from lines: [String]) -> String {
        let ignorePrefixes = [
            "hóa đơn", "hoa don", "phiếu thanh toán", "phieu thanh toan",
            "receipt", "invoice", "bill", "phiếu thu", "chuyển khoản",
            "kính chào", "cảm ơn", "thank you", "welcome", "ngày", "date"
        ]
        
        // Merchant is usually within the first 4 valid lines
        for line in lines.prefix(4) {
            let lower = line.lowercased()
            let shouldIgnore = ignorePrefixes.contains { lower.contains($0) }
            
            // Filter out phone numbers or pure numbers
            let digitsOnly = line.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
            let isMostlyNumbers = Double(digitsOnly.count) / Double(max(1, line.count)) > 0.5
            
            if !shouldIgnore && !isMostlyNumbers && line.count > 2 {
                return line.prefix(1).uppercased() + line.dropFirst()
            }
        }
        
        return "Receipt Expense"
    }
    
    // MARK: - Category Detection
    private static func detectCategory(from lines: [String], title: String) -> TransactionCategory {
        let fullContent = (lines.joined(separator: " ") + " " + title).lowercased()
        
        let categoryMapping: [(keywords: [String], category: TransactionCategory)] = [
            (["highlands", "phúc long", "phuc long", "starbucks", "coffee", "cà phê", "cafe", "trà sữa", "bún", "phở", "cơm", "restaurant", "quán ăn", "nhà hàng", "pizza", "kfc", "lotteria", "food", "bbq"], .food),
            (["winmart", "co.opmart", "bach hoa xanh", "bách hóa xanh", "circle k", "ministop", "7-eleven", "gs25", "siêu thị", "mart", "shopping", "shopee", "lazada", "tiki", "zara", "uniqlo"], .shopping),
            (["xăng", "petrolimex", "pvoil", "grab", "be", "taxi", "gửi xe", "parking", "transport"], .transport),
            (["cgv", "lotte cinema", "bhd", "cinema", "rạp phim", "karaoke", "billiards", "game"], .entertainment),
            (["pharmacy", "nhà thuốc", "long châu", "an khang", "bệnh viện", "phòng khám", "medical", "hospital"], .health),
            (["tiền điện", "tiền nước", "evn", "internet", "viettel", "fpt", "vnpt", "bill"], .bills),
            (["fahasa", "phương nam", "nhà sách", "sách", "book", "course"], .education),
            (["spa", "salon", "barber", "cắt tóc", "nail", "skincare"], .personalCare),
            (["gym", "fitness", "yoga", "cầu lông", "pickleball", "tiền sân"], .sports)
        ]
        
        for mapping in categoryMapping {
            if mapping.keywords.contains(where: { fullContent.contains($0) }) {
                return mapping.category
            }
        }
        
        return .other
    }
    
    // MARK: - Date Extraction
    private static func extractDate(from lines: [String]) -> Date? {
        let datePattern = #"(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{2,4})"#
        guard let regex = try? NSRegularExpression(pattern: datePattern) else { return nil }
        
        for line in lines {
            let nsString = line as NSString
            if let match = regex.firstMatch(in: line, options: [], range: NSRange(location: 0, length: nsString.length)) {
                let dayStr = nsString.substring(with: match.range(at: 1))
                let monthStr = nsString.substring(with: match.range(at: 2))
                var yearStr = nsString.substring(with: match.range(at: 3))
                
                if yearStr.count == 2 {
                    yearStr = "20" + yearStr
                }
                
                let formatter = DateFormatter()
                formatter.dateFormat = "dd/MM/yyyy"
                formatter.locale = Locale(identifier: "en_US_POSIX")
                
                if let parsedDate = formatter.date(from: "\(dayStr)/\(monthStr)/\(yearStr)") {
                    return parsedDate
                }
            }
        }
        return nil
    }
}
