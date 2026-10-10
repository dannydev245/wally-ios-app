//
//  TransactionsScreen.swift
//  RandumApp
//
//  Created by dannyduy on 3/10/26.
//

import SwiftUI

struct TransactionsScreen: View {
    @ObservedObject var viewModel: TransactionsViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                themeManager.currentAccent.backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    List {
                        // MARK: - Header Filter & Search Area
                        Section{
                            VStack(spacing: 12) {
                                // Search Field
                                HStack(spacing: 10) {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundStyle(AppColors.textSecondary)
                                    
                                    TextField("Search transactions...", text: $viewModel.searchText)
                                        .foregroundStyle(AppColors.textPrimary)
                                    
                                    if !viewModel.searchText.isEmpty {
                                        Button {
                                            viewModel.searchText = ""
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundStyle(AppColors.textSecondary)
                                        }
                                    }
                                }
                                .padding(12)
                                .background(themeManager.currentAccent.inputBackgroundColor)
                                .clipShape(Capsule())
                                
                                // Type Filter Chips (All, Expense, Income)
                                HStack(spacing: 4) {
                                    ForEach(TransactionFilterType.allCases, id: \.self) { type in
                                        Button {
                                            withAnimation {
                                                viewModel.selectedTypeFilter = type
                                            }
                                        } label: {
                                            Text(type.rawValue)
                                                .font(.system(size: 14, weight: .semibold))
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                                .background(
                                                    viewModel.selectedTypeFilter == type
                                                    ? themeManager.currentAccent.primaryColor
                                                    : themeManager.currentAccent.inputBackgroundColor
                                                )
                                                .foregroundStyle(viewModel.selectedTypeFilter == type ? .white : AppColors.textSecondary)
                                                .clipShape(Capsule())
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    
                                    Spacer()
                                    
                                    // Date Range Picker Menu
                                    Menu {
                                        ForEach(DateRangeFilter.allCases, id: \.self) { range in
                                            Button(range.rawValue) {
                                                viewModel.selectedDateRange = range
                                            }
                                        }
                                    } label: {
                                        HStack(spacing: 4) {
                                            Text(viewModel.selectedDateRange.rawValue)
                                                .font(.system(size: 14, weight: .medium))
                                                .frame(minWidth: 84)
                                                .lineLimit(1)
                                            
                                            Image(systemName: "chevron.down")
                                                .font(.system(size: 10))
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(themeManager.currentAccent.inputBackgroundColor)
                                        .foregroundStyle(AppColors.textPrimary)
                                        .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .listRowInsets(EdgeInsets())
                        .padding(.horizontal, 12)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listSectionSeparator(.hidden)
                        
                        // MARK: - Body List
                        if viewModel.groupedTransactions.isEmpty {
                            VStack(alignment: .center,spacing: 12) {
                                Spacer()
                                Image(systemName: "tray.fill")
                                    .font(.system(size: 70))
                                    .foregroundStyle(AppColors.textSecondary.opacity(0.5))
                                
                                Text("No transactions found")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(AppColors.textPrimary)
                                
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        } else {
                            ForEach(viewModel.groupedTransactions) { group in
                                Section {
                                    ForEach(group.items) { tx in
                                        TransactionRowView(transaction: tx)
                                            .padding(.vertical, 6)
                                            .listRowInsets(EdgeInsets())
                                            .listRowBackground(Color.clear)
                                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                                Button(role: .destructive) {
                                                    withAnimation(.easeInOut(duration: 0.25)) {
                                                        viewModel.deleteTransaction(tx)
                                                    }
                                                } label: {
                                                    Label("Delete", systemImage: "trash.fill")
                                                }
                                                .tint(.red)
                                                
                                                Button {
                                                    viewModel.editingTransaction = tx
                                                    viewModel.showFormSheet = true
                                                } label: {
                                                    Label("Edit", systemImage: "pencil")
                                                }
                                                .tint(.orange)
                                            }
                                    }
                                } header: {
                                    Text(group.dateTitle)
                                        .font(.system(size: 14, weight: .bold))
                                        .textCase(nil)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                } footer: {
                                    EmptyView()
                                }
                                .listSectionSeparator(.hidden)
                                .padding(.horizontal, 12)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .environment(\.defaultMinListHeaderHeight, 0)
                }
            }
            .navigationTitle("Transactions")
            .navigationBarTitleDisplayMode(.inline)
            
            // MARK: - Sheet Create / Edit
            .sheet(isPresented: $viewModel.showFormSheet) {
                TransactionFormSheet(transactionToEdit: viewModel.editingTransaction) { title, amount, date, type, category in
                    if let editing = viewModel.editingTransaction {
                        let updated = TransactionItem(
                            id: editing.id,
                            title: title,
                            amount: amount,
                            date: date,
                            type: type,
                            category: category
                        )
                        viewModel.updateTransaction(updated)
                    }
                }
                .presentationDetents([.fraction(0.68), .large])
                .presentationDragIndicator(.visible)
                //                .presentationDetents([.height(520)])
            }
        }
        .tint(themeManager.currentAccent.primaryColor)
    }
}

#Preview {
    TransactionsScreen(
        viewModel: TransactionsViewModel(),
    )
}
