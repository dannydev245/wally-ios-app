//
//  ReceiptOCRParser.swift
//  RandumApp
//
//  Created by dannyduy on 28/10/26.
//

import Foundation

struct ReceiptOCRParser {
    static func parse(recognizedLines: [String]) -> ParsedTransactionResult {
        let cleanedLines = recognizedLines
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        let title = extractMerchantTitle(from: cleanedLines)
        let amount = extractTotalAmount(from: cleanedLines)
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
        let normalizedLines = lines.map { removeAccents(from: $0.lowercased()) }
        
        // Từ khóa ưu tiên của khối tính tiền / thanh toán
        let targetKeywords = [
            "thanh tien", "thanh toan", "zalopay", "momo", "vnpay",
            "tien mat", "cash", "visa", "master", "chuyen khoan",
            "tong tien", "tong cong", "total", "amount due", "grand total"
        ]
        
        // 1. Dò theo khối từ khóa thanh toán (duyệt từ dưới lên)
        for (index, line) in normalizedLines.enumerated().reversed() {
            if targetKeywords.contains(where: { line.contains($0) }) {
                // Kiểm tra trực tiếp trên cùng dòng
                if let amount = extractValidCurrency(from: lines[index]) {
                    return amount
                }
                
                // Thu thập các số tiền nằm trong 6 dòng phía sau (xử lý hóa đơn chia cột)
                var candidateAmounts: [Double] = []
                for offset in 1...6 {
                    let nextIndex = index + offset
                    if nextIndex < lines.count {
                        let nextNormLine = normalizedLines[nextIndex]
                        
                        // Bỏ qua các dòng nhãn hệ thống, điểm thưởng
                        if isMetadataLine(nextNormLine) {
                            continue
                        }
                        
                        if let amount = extractValidCurrency(from: lines[nextIndex]) {
                            candidateAmounts.append(amount)
                        }
                    }
                }
                
                // Con số cuối cùng trong khối thanh toán chính là số tiền chốt sổ sau giảm giá
                if let finalAmount = candidateAmounts.last {
                    return finalAmount
                }
            }
        }
        
        // 2. Fallback: Nếu không bắt được nhãn, quét các con số tiền hợp lệ
        var validAmounts: [Double] = []
        for (index, line) in lines.enumerated() {
            let norm = normalizedLines[index]
            if isMetadataLine(norm) {
                continue
            }
            if let amount = extractValidCurrency(from: line) {
                validAmounts.append(amount)
            }
        }
        
        return validAmounts.last ?? 0
    }
    
    private static func isMetadataLine(_ normLine: String) -> Bool {
        let blacklist = [
            "thu ngan", "ma ptt", "ma cqt", "ma xac thuc", "so tham chieu",
            "tham chieu", "dien thoai", "tel", "ext", "gio", "time",
            "date", "diem", "point", "wifi", "password", "mst",
            "sale type", "invoice", "hang the", "diamond"
        ]
        return blacklist.contains(where: { normLine.contains($0) })
    }
    
    // MARK: - Validate Currency
    private static func extractValidCurrency(from text: String) -> Double? {
        let pattern = #"(\d{1,3}(?:[\.,]\d{3})+(?:[\.,]\d+)?|\d+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        
        let nsString = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
        
        for match in matches.reversed() {
            var numberString = nsString.substring(with: match.range)
            
            // Xóa dấu phân tách hàng nghìn
            let dotParts = numberString.components(separatedBy: ".")
            let commaParts = numberString.components(separatedBy: ",")
            
            if dotParts.count > 1 && dotParts.dropFirst().allSatisfy({ $0.count == 3 }) {
                numberString = numberString.replacingOccurrences(of: ".", with: "")
            } else if commaParts.count > 1 && commaParts.dropFirst().allSatisfy({ $0.count == 3 }) {
                numberString = numberString.replacingOccurrences(of: ",", with: "")
            } else {
                numberString = numberString.replacingOccurrences(of: ",", with: ".")
            }
            
            // Lọc chặt chẽ:
            // - Đếm số lượng chữ số thuần túy: mã tham chiếu/PTT thường >= 10 số (ví dụ: 206902261005864 có 15 số)
            // - Số tiền thông thường từ 1.000 đến dưới 200 triệu đồng
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
    
    // MARK: - Merchant Title Extraction
    private static func extractMerchantTitle(from lines: [String]) -> String {
        let knownBrands = [
            "phuclong", "phuc long", "highlands", "starbucks",
            "winmart", "circle k", "ministop", "7-eleven", "gs25"
        ]
        
        let ignorePrefixes = [
            "hoa don", "phieu thanh toan", "receipt", "invoice",
            "bill", "phieu thu", "chuyen khoan", "kinh chao", "cam on"
        ]
        
        let addressIndicators = [
            "duong", "phuong", "quan", "tp.", "tp ", "thanh pho",
            "ho chi minh", "ha noi", "hcm", "hn", "dien thoai", "tel", "ext", "siuce"
        ]
        
        let searchWindow = lines.prefix(6)
        
        // 1. Quét tìm thương hiệu lớn trước
        for line in searchWindow {
            let norm = removeAccents(from: line.lowercased())
            if let brand = knownBrands.first(where: { norm.contains($0) }) {
                return brand == "phuclong" ? "Phúc Long" : brand.capitalized
            }
        }
        
        // 2. Nếu không thuộc brand có sẵn, loại trừ địa chỉ và lấy dòng tên cửa hàng đầu tiên
        for line in searchWindow {
            let norm = removeAccents(from: line.lowercased())
            
            if ignorePrefixes.contains(where: { norm.contains($0) }) {
                continue
            }
            
            // Bỏ qua dòng chứa từ định danh địa chỉ
            if addressIndicators.contains(where: { norm.contains($0) }) {
                continue
            }
            
            // Bỏ qua nếu bắt đầu bằng số nhà (vd: "493A", "12/3")
            if let firstWord = line.components(separatedBy: " ").first,
               firstWord.rangeOfCharacter(from: .decimalDigits) != nil {
                continue
            }
            
            let digitsCount = line.filter { $0.isNumber }.count
            if Double(digitsCount) / Double(max(1, line.count)) > 0.3 {
                continue
            }
            
            if line.count >= 2 {
                return line.prefix(1).uppercased() + line.dropFirst()
            }
        }
        
        return "Receipt Expense"
    }
    
    // MARK: - Category Detection
    private static func detectCategory(from lines: [String], title: String) -> TransactionCategory {
        let fullContent = (lines.joined(separator: " ") + " " + title).lowercased()
        let normContent = removeAccents(from: fullContent)
        
        let categoryMapping: [(keywords: [String], category: TransactionCategory)] = [
            (["highlands", "phuc long", "starbucks", "coffee", "ca phe", "cafe", "tra sua", "bun", "pho", "com", "restaurant", "quan an", "nha hang", "pizza", "kfc", "lotteria", "food", "bbq", "hong tra", "chanh"], .food),
            (["winmart", "co.opmart", "bach hoa xanh", "circle k", "ministop", "7-eleven", "gs25", "sieu thi", "mart", "shopping", "shopee", "lazada", "tiki", "zara", "uniqlo"], .shopping),
            (["xang", "petrolimex", "pvoil", "grab", "be", "taxi", "gui xe", "parking", "transport"], .transport),
            (["cgv", "lotte cinema", "bhd", "cinema", "rap phim", "karaoke", "billiards", "game"], .entertainment),
            (["pharmacy", "nha thuoc", "long chau", "an khang", "benh vien", "phong kham", "medical", "hospital"], .health),
            (["tien dien", "tien nuoc", "evn", "internet", "viettel", "fpt", "vnpt", "bill"], .bills),
            (["fahasa", "phuong nam", "nha sach", "sach", "book", "course"], .education),
            (["spa", "salon", "barber", "cat toc", "nail", "skincare"], .personalCare),
            (["gym", "fitness", "yoga", "cau long", "pickleball", "tien san"], .sports)
        ]
        
        for mapping in categoryMapping {
            if mapping.keywords.contains(where: { normContent.contains($0) }) {
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
    
    // MARK: - Helper Remove Accents
    private static func removeAccents(from string: String) -> String {
        return string
            .folding(options: .diacriticInsensitive, locale: Locale(identifier: "vi_VN"))
            .replacingOccurrences(of: "đ", with: "d")
            .replacingOccurrences(of: "Đ", with: "D")
    }
}
