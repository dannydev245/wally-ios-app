//
//  AnalyzeViewModel.swift
//  RandumApp
//
//  Created by dannyduy on 6/10/26.
//

import Foundation
import Combine

class AnalyzeViewModel: ObservableObject {
    @Published var selectedScope: TimeScope = .month
    @Published var currentDate: Date = Date()
    
    @Published var periodIncome: Double = 0
    @Published var periodExpense: Double = 0
    @Published var chartData: [ScopeChartData] = []
    @Published var categoryBreakdown: [CategoryBreakdownItem] = []
    
    var netFlow: Double {
        periodIncome - periodExpense
    }
    
    var periodTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        
        switch selectedScope {
        case .day:
            formatter.dateFormat = "EEE, dd MMM yyyy"
            return formatter.string(from: currentDate)
        case .week:
            let calendar = Calendar.current
            if let start = calendar.dateInterval(of: .weekOfYear, for: currentDate)?.start,
               let end = calendar.date(byAdding: .day, value: 6, to: start) {
                let startFormat = DateFormatter()
                startFormat.dateFormat = "dd MMM"
                let endFormat = DateFormatter()
                endFormat.dateFormat = "dd MMM yyyy"
                return "\(startFormat.string(from: start)) - \(endFormat.string(from: end))"
            }
            return "This Week"
        case .month:
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: currentDate)
        case .year:
            formatter.dateFormat = "yyyy"
            return formatter.string(from: currentDate)
        }
    }
    
    // MARK: - Move Period
    func movePeriod(by step: Int) {
        let calendar = Calendar.current
        var component: Calendar.Component = .month
        switch selectedScope {
        case .day: component = .day
        case .week: component = .weekOfYear
        case .month: component = .month
        case .year: component = .year
        }
        
        if let newDate = calendar.date(byAdding: component, value: step, to: currentDate) {
            currentDate = newDate
        }
    }
    
    // MARK: - Update analytics
    func updateAnalytics(from transactions: [TransactionItem]) {
        let calendar = Calendar.current
        
        // 1. Filter scoped transactions data
        let scopedTransactions = transactions.filter { item in
            switch selectedScope {
            case .day:
                return calendar.isDate(item.date, inSameDayAs: currentDate)
            case .week:
                return calendar.isDate(item.date, equalTo: currentDate, toGranularity: .weekOfYear) &&
                calendar.isDate(item.date, equalTo: currentDate, toGranularity: .yearForWeekOfYear)
            case .month:
                return calendar.isDate(item.date, equalTo: currentDate, toGranularity: .month) &&
                calendar.isDate(item.date, equalTo: currentDate, toGranularity: .year)
            case .year:
                return calendar.isDate(item.date, equalTo: currentDate, toGranularity: .year)
            }
        }
        
        // 2. Calculate periodIncome & periodExpense
        self.periodIncome = scopedTransactions
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }
        
        self.periodExpense = scopedTransactions
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
        
        // 3. buildChartData
        buildChartData(from: scopedTransactions, calendar: calendar)
        
        // 4. buildCategoryBreakdown
        buildCategoryBreakdown(from: scopedTransactions)
    }
    
    // MARK: - buildChartData
    private func buildChartData(from items: [TransactionItem], calendar: Calendar) {
        var result: [ScopeChartData] = []
        
        switch selectedScope {
        case .day:
            let intervals = [
                ("Morning\n(6-12h)", 6..<12),
                ("Afternoon\n(12-18h)", 12..<18),
                ("Evening\n(18-24h)", 18..<24),
                ("Night\n(0-6h)", 0..<6)
            ]
            for (label, range) in intervals {
                let intervalItems = items.filter {
                    let hour = calendar.component(.hour, from: $0.date)
                    return range.contains(hour)
                }
                let income = intervalItems.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
                let expense = intervalItems.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
                result.append(ScopeChartData(label: label, amount: income, type: .income))
                result.append(ScopeChartData(label: label, amount: expense, type: .expense))
            }
            
        case .week:
            let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
            for (index, dayName) in days.enumerated() {
                let weekdayTarget = (index + 2) > 7 ? 1 : (index + 2) // Calendar weekday: 1=Sun, 2=Mon...
                let dayItems = items.filter { calendar.component(.weekday, from: $0.date) == weekdayTarget }
                let income = dayItems.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
                let expense = dayItems.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
                result.append(ScopeChartData(label: dayName, amount: income, type: .income))
                result.append(ScopeChartData(label: dayName, amount: expense, type: .expense))
            }
            
        case .month:
            var weeklyIncome = [0.0, 0.0, 0.0, 0.0]
            var weeklyExpense = [0.0, 0.0, 0.0, 0.0]
            for item in items {
                let day = calendar.component(.day, from: item.date)
                let weekIdx = min((day - 1) / 7, 3)
                if item.type == .income { weeklyIncome[weekIdx] += item.amount }
                else { weeklyExpense[weekIdx] += item.amount }
            }
            for i in 0..<4 {
                result.append(ScopeChartData(label: "W\(i + 1)", amount: weeklyIncome[i], type: .income))
                result.append(ScopeChartData(label: "W\(i + 1)", amount: weeklyExpense[i], type: .expense))
            }
            
        case .year:
            let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
            for (index, monthName) in months.enumerated() {
                let mItems = items.filter { calendar.component(.month, from: $0.date) == (index + 1) }
                let income = mItems.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
                let expense = mItems.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
                result.append(ScopeChartData(label: monthName, amount: income, type: .income))
                result.append(ScopeChartData(label: monthName, amount: expense, type: .expense))
            }
        }
        
        self.chartData = result
    }
    
    // MARK: - buildCategoryBreakdown
    private func buildCategoryBreakdown(from items: [TransactionItem]) {
        let expenses = items.filter { $0.type == .expense }
        let total = expenses.reduce(0) { $0 + $1.amount }
        
        guard total > 0 else {
            self.categoryBreakdown = []
            return
        }
        
        // 1. group category
        var grouped: [TransactionCategory: Double] = [:]
        for item in expenses {
            grouped[item.category, default: 0] += item.amount
        }
        
        // 2. SortedList
        let sortedList = grouped.map { cat, amount in
            CategoryBreakdownItem(category: cat, totalAmount: amount, percentage: amount / total)
        }
        .sorted(by: { $0.totalAmount > $1.totalAmount })
        
        // 3. Top 4 and others
        let topLimit = 4
        if sortedList.count <= topLimit {
            self.categoryBreakdown = sortedList
        } else {
            // topItems take 4
            let topItems = Array(sortedList.prefix(topLimit))
            
            // remainingAmount into otherItem
            let remainingAmount = sortedList.dropFirst(topLimit).reduce(0) { $0 + $1.totalAmount }
            let otherItem = CategoryBreakdownItem(
                category: .other,
                totalAmount: remainingAmount,
                percentage: remainingAmount / total
            )
            
            self.categoryBreakdown = topItems + [otherItem]
        }
    }
}
