//
//  TransactionsScreen.swift
//  RandumApp
//
//  Created by dannyduy on 3/10/26.
//

import SwiftUI

struct TransactionsScreen: View {
    @ObservedObject var viewModel: TransactionsViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                themeManager.currentAccent.backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    List {
                        // MARK: - Header Filter & Search Area
                        filterHeaderSection
                        
                        // MARK: - Body List
                        if viewModel.groupedTransactions.isEmpty {
                            emptyStateSection
                        } else {
                            transactionListSections
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .environment(\.defaultMinListHeaderHeight, 0)
                }
                .padding(.top)
            }
            .navigationBarHidden(true)
            // MARK: - Sheet Edit
            .sheet(isPresented: $viewModel.showFormSheet) {
                TransactionFormSheet(transactionToEdit: viewModel.editingTransaction) { updatedTrx in
                    viewModel.updateTransaction(updatedTrx)
                }
                .presentationDetents([.fraction(0.68), .large])
                .presentationDragIndicator(.visible)
            }
        }
        .tint(themeManager.currentAccent.primaryColor)
    }
    
    @ViewBuilder
    private var filterHeaderSection: some View {
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
                            Text(type.localizedTitle)
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
                    let isFilterActive = viewModel.selectedDateRange != .all
                    
                    Menu {
                        ForEach(DateRangeFilter.allCases, id: \.self) { range in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.selectedDateRange = range
                                }
                            } label: {
                                HStack {
                                    Text(range.localizedTitle)
                                    if viewModel.selectedDateRange == range {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: isFilterActive ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(isFilterActive ? .white : AppColors.textPrimary)
                            .frame(width: 36, height: 36)
                            .background(
                                isFilterActive
                                ? themeManager.currentAccent.primaryColor
                                : themeManager.currentAccent.inputBackgroundColor
                            )
                            .clipShape(Circle())
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
    }
    
    @ViewBuilder
    private var emptyStateSection: some View {
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
    }
    
    @ViewBuilder
    private var transactionListSections: some View {
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
                Text(formatMonthHeader(group.date))
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
    
    private func formatMonthHeader(_ date: Date) -> String {
        let style = Date.FormatStyle.dateTime.month(.abbreviated).year()
        let rawString = date.formatted(style.locale(themeManager.currentLanguage.locale))
        return rawString.prefix(1).uppercased() + rawString.dropFirst()
    }
}

#Preview {
    TransactionsScreen(
        viewModel: TransactionsViewModel(),
    )
}
