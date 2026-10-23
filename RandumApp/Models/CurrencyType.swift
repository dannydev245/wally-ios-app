//
//  CurrencyType.swift
//  RandumApp
//
//  Created by dannyduy on 22/10/26.
//

import Foundation

enum CurrencyType: String, CaseIterable, Identifiable {
    case vnd = "VND (₫)"
    case usd = "USD ($)"
    
    var id: String { rawValue }
    
    var symbol: String {
        switch self {
        case .vnd: return "₫"
        case .usd: return "$"
        }
    }
    
    func format(amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        
        switch self {
        case .vnd:
            formatter.maximumFractionDigits = 0
            let formattedNumber = formatter.string(from: NSNumber(value: amount)) ?? "\(Int(amount))"
            return "\(formattedNumber) ₫"
            
        case .usd:
            formatter.maximumFractionDigits = 0
            let formattedNumber = formatter.string(from: NSNumber(value: amount)) ?? String(format: "%.2f", amount)
            return "$\(formattedNumber)"
        }
    }
    
    func formatCompact(amount: Double) -> String {
        let absAmount = abs(amount)
        let sign = amount < 0 ? "-" : ""
        
        switch self {
        case .vnd:
            if absAmount >= 1_000_000_000 {
                return "\(sign)\(String(format: "%.1f", absAmount / 1_000_000_000))B ₫"
            } else if absAmount >= 1_000_000 {
                return "\(sign)\(String(format: "%.1f", absAmount / 1_000_000))M ₫"
            } else if absAmount >= 1_000 {
                return "\(sign)\(String(format: "%.0f", absAmount / 1_000))k ₫"
            } else {
                return "\(sign)\(Int(absAmount)) ₫"
            }
            
        case .usd:
            if absAmount >= 1_000_000_000 {
                return "\(sign)$\(String(format: "%.1f", absAmount / 1_000_000_000))B"
            } else if absAmount >= 1_000_000 {
                return "\(sign)$\(String(format: "%.1f", absAmount / 1_000_000))M"
            } else if absAmount >= 1_000 {
                return "\(sign)$\(String(format: "%.0f", absAmount / 1_000))k"
            } else {
                return "\(sign)$\(String(format: "%.0f", absAmount))"
            }
        }
    }
}
