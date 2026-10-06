//
//  MonthlyChartData.swift
//  RandumApp
//
//  Created by dannyduy on 5/10/26.
//

import Foundation

struct MonthlyChartData: Identifiable {
    let id = UUID()
    let weekLabel: String
    let amount: Double
    let type: TransactionType
}

enum TimeScope: String, CaseIterable, Identifiable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
    case year = "Year"
    
    var id: String { self.rawValue }
}

struct ScopeChartData: Identifiable {
    let id = UUID()
    let label: String
    let amount: Double
    let type: TransactionType
}

struct CategoryBreakdownItem: Identifiable {
    let id = UUID()
    let category: TransactionCategory
    let totalAmount: Double
    let percentage: Double
}
