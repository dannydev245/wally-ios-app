//
//  HomeViewModel.swift
//  RandumApp
//
//  Created by dannyduy on 3/10/26.
//

import Foundation
import Combine

class HomeViewModel: ObservableObject {
    @Published var currentUser: User
    @Published var totalBalance: Double = 0
    @Published var monthlyIncome: Double = 0
    @Published var monthlyExpense: Double = 0
    @Published var recentTransactions: [TransactionItem] = []
    @Published var chartData: [MonthlyChartData] = []
    
    init(user: User) {
        self.currentUser = user
    }
    
    // Update data when transactions list change
    func updateData(from transactions: [TransactionItem]) {
        let calendar = Calendar.current
        let now = Date()
        
        // 1. Filter data in current month
        let currentMonthTransactions = transactions.filter {
            calendar.isDate($0.date, equalTo: now, toGranularity: .month) &&
            calendar.isDate($0.date, equalTo: now, toGranularity: .year)
        }
        
        // 2. Calculate Total in & outcome (All-time Total)
        let totalIncome = transactions
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }
        
        let totalExpense = transactions
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
        
        self.monthlyIncome = totalIncome    // Tổng thu toàn bộ
        self.monthlyExpense = totalExpense  // Tổng chi toàn bộ
        self.totalBalance = totalIncome - totalExpense // Số dư thực tế toàn bộ
        
        // 3. Get max 5 recent transactions
        self.recentTransactions = Array(
            transactions
                .sorted(by: { $0.date > $1.date })
                .prefix(5)
        )
        
        // 4. Calculate 4 week in month for Chart
        calculateWeeklyChart(from: currentMonthTransactions)
    }
    
    private func calculateWeeklyChart(from monthItems: [TransactionItem]) {
            var weeklyIncomes: [Double] = [0, 0, 0, 0]
            var weeklyExpenses: [Double] = [0, 0, 0, 0]
            let calendar = Calendar.current
            
            for item in monthItems {
                let day = calendar.component(.day, from: item.date)
                let weekIndex = min((day - 1) / 7, 3)
                
                if item.type == .income {
                    weeklyIncomes[weekIndex] += item.amount
                } else {
                    weeklyExpenses[weekIndex] += item.amount
                }
            }
            
            var generatedData: [MonthlyChartData] = []
            for i in 0..<4 {
                let label = "W\(i + 1)"
                generatedData.append(MonthlyChartData(weekLabel: label, amount: weeklyIncomes[i], type: .income))
                generatedData.append(MonthlyChartData(weekLabel: label, amount: weeklyExpenses[i], type: .expense))
            }
            
            self.chartData = generatedData
        }
}
