//
//  Transaction.swift
//  RandumApp
//
//  Created by dannyduy on 4/10/26.
//

import Foundation

enum TransactionType: String, CaseIterable, Codable, Identifiable {
    case expense = "Expense"
    case income = "Income"
    
    var id: String{ rawValue }
}

enum TransactionCategory: String, CaseIterable, Codable, Identifiable {
    // Expense Categories
    case shopping = "Shopping"
    case food = "Food & Beverage"
    case transport = "Transportation"
    case bills = "Bills & Utilities"
    case entertainment = "Entertainment"
    
    // Income Categories
    case salary = "Salary"
    case bonus = "Bonus"
    case investment = "Investment"
    case other = "Other"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .food: return "fork.knife"
        case .shopping: return "cart.fill"
        case .transport: return "car.fill"
        case .bills: return "doc.text.fill"
        case .entertainment: return "film.fill"
        case .salary: return "banknote.fill"
        case .bonus: return "gift.fill"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .other: return "ellipsis.circle.fill"
        }
    }
    
    // Filter category -> Type
    static func categories(for type: TransactionType) -> [TransactionCategory] {
        switch type {
        case .expense:
            return [.shopping, .food, .transport, .bills, .entertainment, .other]
        case .income:
            return [.salary, .bonus, .investment, .other]
        }
    }
}

struct TransactionItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var amount: Double
    var date: Date
    var type: TransactionType
    var category: TransactionCategory
}

struct TransactionGroup: Identifiable {
    let id = UUID()
    let dateTitle: String 
    let items: [TransactionItem]
}
