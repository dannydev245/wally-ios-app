//
//  TransactionsScreen.swift
//  RandumApp
//
//  Created by dannyduy on 3/10/26.
//

import SwiftUI

struct TransactionsScreen: View {
    @ObservedObject var viewModel: TransactionsViewModel
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                AppColors.background
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
                                .background(AppColors.inputBackground)
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
                                                .background(viewModel.selectedTypeFilter == type ? AppColors.primary : AppColors.inputBackground)
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
                                        .background(AppColors.inputBackground)
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
                                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
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
                
                // MARK: - Floating Add Button
                DraggableFAB {
                    viewModel.editingTransaction = nil
                    viewModel.showFormSheet = true
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
                    } else {
                        viewModel.addTransaction(title: title, amount: amount, date: date, type: type, category: category)
                    }
                }
                .presentationDetents([.fraction(0.68), .large])
                .presentationDragIndicator(.visible)
//                .presentationDetents([.height(520)])
            }
        }
    }
}

#Preview {
    TransactionsScreen(
        viewModel: TransactionsViewModel(),
    )
}
