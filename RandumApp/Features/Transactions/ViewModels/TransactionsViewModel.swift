//
//  TransactionViewModel.swift
//  RandumApp
//
//  Created by dannyduy on 4/10/26.
//

import Foundation
import Combine

enum TransactionFilterType: String, CaseIterable {
    case all = "All"
    case expense = "Expense"
    case income = "Income"
}

enum DateRangeFilter: String, CaseIterable {
    case all = "All Time"
    case thisMonth = "This Month"
    case last7Days = "Last 7 Days"
}

class TransactionsViewModel: ObservableObject {
    @Published var transactions: [TransactionItem] = []
    @Published var searchText: String = ""
    @Published var selectedTypeFilter: TransactionFilterType = .all
    @Published var selectedDateRange: DateRangeFilter = .all
    
    // Manage Modal Edit
    @Published var showFormSheet: Bool = false
    @Published var editingTransaction: TransactionItem? = nil
    
    init() {
        loadTransactions()
    }
    
    // MARK: - CRUD
    func loadTransactions() {
        self.transactions = UserDefaults.standard.savedTransactions
    }
    
    private func saveTransactions() {
        UserDefaults.standard.savedTransactions = self.transactions
    }
    
    func addTransaction(title: String, amount: Double, date: Date, type: TransactionType, category: TransactionCategory) {
        let newTx = TransactionItem(
            title: title,
            amount: amount,
            date: date,
            type: type,
            category: category
        )
        transactions.append(newTx)
        saveTransactions()
    }
    
    func updateTransaction(_ item: TransactionItem) {
        if let index = transactions.firstIndex(where: { $0.id == item.id }) {
            transactions[index] = item
            saveTransactions()
        }
    }
    
    func deleteTransaction(_ item: TransactionItem) {
        transactions.removeAll { $0.id == item.id }
        saveTransactions()
    }
    
    // MARK: - Filter & Search Output (Sorted newest to oldest)
    var filteredTransactions: [TransactionItem] {
        let calendar = Calendar.current
        let now = Date()
        
        return transactions.filter { item in
            // Search text
            let matchesSearch = searchText.isEmpty || item.title.localizedCaseInsensitiveContains(searchText)
            
            // Type filter
            let matchesType: Bool
            switch selectedTypeFilter {
            case .all: matchesType = true
            case .expense: matchesType = item.type == .expense
            case .income: matchesType = item.type == .income
            }
            
            // Date range filter
            let matchesDate: Bool
            switch selectedDateRange {
            case .all:
                matchesDate = true
            case .thisMonth:
                matchesDate = calendar.isDate(item.date, equalTo: now, toGranularity: .month)
            case .last7Days:
                if let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now) {
                    matchesDate = item.date >= sevenDaysAgo
                } else {
                    matchesDate = true
                }
            }
            
            return matchesSearch && matchesType && matchesDate
        }
        .sorted { $0.date > $1.date } // From nearest to farthest
    }
    
    // MARK: - Grouped by Month
    var groupedTransactions: [TransactionGroup] {
        let sorted = filteredTransactions
        let calendar = Calendar.current
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        
        let groupedDictionary = Dictionary(grouping: sorted) { item in
            let components = calendar.dateComponents([.year, .month], from: item.date)
            return calendar.date(from: components) ?? item.date
        }
        
        return groupedDictionary.keys
            .sorted(by: >)
            .map { monthDate in
                TransactionGroup(
                    dateTitle: formatter.string(from: monthDate),
                    items: groupedDictionary[monthDate] ?? []
                )
            }
    }
    
    // MARK: - Clear All Transactions (Xóa sạch danh sách giao dịch)
    func clearAllTransactions() {
        self.transactions.removeAll()
        UserDefaults.standard.removeObject(forKey: AppStorageKeys.userTransaction)
    }
}
