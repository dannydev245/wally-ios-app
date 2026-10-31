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
    
    var localizedTitle: LocalizedStringResource {
        switch self {
        case .expense: return "Expense"
        case .income: return "Income"
        }
    }
}

enum TransactionCategory: String, CaseIterable, Codable, Identifiable {
    // MARK: - Expense Categories
    case food = "Food & Beverage"
    case shopping = "Shopping"
    case transport = "Transportation"
    case bills = "Bills & Utilities"
    case housing = "Housing"
    case entertainment = "Entertainment"
    case sports = "Sports & Fitness"
    case health = "Health & Medical"
    case education = "Education"
    case travel = "Travel"
    case personalCare = "Personal Care"
    case giftsDonations = "Gifts & Donations"
    
    // MARK: - Income Categories
    case salary = "Salary"
    case bonus = "Bonus"
    case investment = "Investment"
    case freelance = "Freelance & Side Hustle"
    case allowance = "Allowance & Gifts"
    case rentalIncome = "Rental Income"
    
    // MARK: - General / Other
    case other = "Other"
    
    var id: String { rawValue }
    
    var localizedTitle: LocalizedStringResource {
        switch self {
            // Expense
        case .food: return "Food & Beverage"
        case .shopping: return "Shopping"
        case .transport: return "Transportation"
        case .bills: return "Bills & Utilities"
        case .housing: return "Housing"
        case .entertainment: return "Entertainment"
        case .sports: return "Sports & Fitness"
        case .health: return "Health & Medical"
        case .education: return "Education"
        case .travel: return "Travel"
        case .personalCare: return "Personal Care"
        case .giftsDonations: return "Gifts & Donations"
            
            // Income
        case .salary: return "Salary"
        case .bonus: return "Bonus"
        case .investment: return "Investment"
        case .freelance: return "Freelance & Side Hustle"
        case .allowance: return "Allowance & Gifts"
        case .rentalIncome: return "Rental Income"
            
            // Other
        case .other: return "Other"
        }
    }
    
    var iconName: String {
        switch self {
            // Expense
        case .food: return "fork.knife"
        case .shopping: return "cart.fill"
        case .transport: return "car.fill"
        case .bills: return "bolt.fill"
        case .housing: return "house.fill"
        case .entertainment: return "tv.fill"
        case .sports: return "figure.run"
        case .health: return "cross.case.fill"
        case .education: return "book.closed.fill"
        case .travel: return "airplane"
        case .personalCare: return "sparkles"
        case .giftsDonations: return "gift.fill"
            
            // Income
        case .salary: return "banknote.fill"
        case .bonus: return "star.circle.fill"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .freelance: return "laptopcomputer"
        case .allowance: return "hand.thumbsup.fill"
        case .rentalIncome: return "building.2.fill"
            
            // Other
        case .other: return "ellipsis.circle.fill"
        }
    }
    
    // Filter category -> Type
    static func categories(for type: TransactionType) -> [TransactionCategory] {
        switch type {
        case .expense:
            return [
                .food,
                .shopping,
                .transport,
                .bills,
                .housing,
                .entertainment,
                .sports,
                .health,
                .education,
                .travel,
                .personalCare,
                .giftsDonations,
                .other
            ]
        case .income:
            return [
                .salary,
                .bonus,
                .investment,
                .freelance,
                .rentalIncome,
                .allowance,
                .other
            ]
        }
    }
}

struct TransactionGroup: Identifiable {
    let id = UUID()
    let date: Date
    let items: [TransactionItem]
}

struct TransactionItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var amount: Double
    var date: Date = Date()
    var type: TransactionType
    var category: TransactionCategory
}

enum TransactionFilterType: String, CaseIterable {
    case all = "All"
    case expense = "Expense"
    case income = "Income"
    
    var id: String { rawValue }
    
    var localizedTitle: LocalizedStringResource {
        switch self {
        case .all: return "All"
        case .expense: return "Expense"
        case .income: return "Income"
        }
    }
}

enum DateRangeFilter: String, CaseIterable {
    case all = "All Time"
    case thisMonth = "This Month"
    case last7Days = "Last 7 Days"
    
    var id: String { rawValue }
    
    var localizedTitle: LocalizedStringResource {
        switch self {
        case .all: return "All Time"
        case .thisMonth: return "This Month"
        case .last7Days: return "Last 7 Days"
        }
    }
}
