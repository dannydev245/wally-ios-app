//
//  HomeScreen.swift
//  RandumApp
//
//  Created by dannyduy on 3/10/26.
//

import SwiftUI
import Charts

struct HomeScreen: View {
    @EnvironmentObject private var userManager: UserManager
    @ObservedObject private var themeManager = ThemeManager.shared

    @StateObject private var viewModel = HomeViewModel()
    @ObservedObject var transactionsViewModel: TransactionsViewModel
    
    
    var onSeeAllTapped: () -> Void
    
    init(
        transactionsViewModel: TransactionsViewModel,
        onSeeAllTapped: @escaping () -> Void
    ) {
        self.transactionsViewModel = transactionsViewModel
        self.onSeeAllTapped = onSeeAllTapped
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // MARK: - Header (Greetings)
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Welcome back,")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(AppColors.textSecondary)
                                
                                Text(userManager.currentUser?.name ?? "user")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundStyle(AppColors.textPrimary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.65)
                                    .allowsTightening(true)
                            }
                            
                            Spacer()
                            
                            ZStack {
                                Circle()
                                    .fill(AppColors.primary.opacity(0.15))
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.system(size: 30, weight: .semibold))
                                    .foregroundStyle(AppColors.primary)
                            }
                        }
                        .padding(.top, 10)
                        
                        // MARK: - Card Balance Overview
                        VStack(alignment: .leading, spacing: 18) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Total Balance")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(.white.opacity(0.85))
                                
                                Text(viewModel.totalBalance.toCurrencyString())
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            
                            HStack(alignment: .center, spacing: 12) {
                                // MARK: - 1. INCOME COLUMN
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.down.left.circle.fill")
                                        .font(.system(size: 30))
                                        .foregroundStyle(AppColors.greenEmerald)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Income")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundStyle(Color.white.opacity(0.85))
                                        
                                        Text(viewModel.monthlyIncome.toCurrencyString())
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundStyle(.white)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.65)
                                            .allowsTightening(true)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                                // MARK: - 2. EXPENSE COLUMN
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.up.right.circle.fill")
                                        .font(.system(size: 26))
                                        .foregroundStyle(AppColors.redBright)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Expense")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundStyle(Color.white.opacity(0.85))
                                        
                                        Text(viewModel.monthlyExpense.toCurrencyString())
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundStyle(.white)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.65)
                                            .allowsTightening(true)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(16)
                        .background(
                            LinearGradient(
                                colors: [AppColors.primary, AppColors.primary.opacity(0.85)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .shadow(color: AppColors.primary.opacity(0.25), radius: 12, y: 6)
                        
                        // MARK: - Month Spending & Income Overview
                        VStack(alignment: .leading, spacing: 18) {
                            // Legend note for chart
                            HStack {
                                Text("Monthly Overview")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(AppColors.textPrimary)
                                
                                Spacer()
                                HStack(spacing: 12) {
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(AppColors.greenEmerald)
                                            .frame(width: 8, height: 8)
                                        Text("Income")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundStyle(AppColors.textSecondary)
                                    }
                                    
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(AppColors.redBright)
                                            .frame(width: 8, height: 8)
                                        Text("Expense")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundStyle(AppColors.textSecondary)
                                    }                                    
                                }
                            }
                                                        
                            if viewModel.chartData.allSatisfy({ $0.amount == 0 }) {
                                Text("No transaction data for this month yet.")
                                    .font(.system(size: 13))
                                    .foregroundStyle(AppColors.textSecondary)
                                    .frame(maxWidth: .infinity, minHeight: 140)
                            } else {
                                Chart(viewModel.chartData) { item in
                                    BarMark(
                                        x: .value("Week", item.weekLabel),
                                        y: .value("Amount", item.amount)
                                    )
                                    .position(by: .value("Type", item.type.rawValue))
                                    .foregroundStyle(
                                        item.type == .income
                                        ? AppColors.greenEmerald
                                        : AppColors.redBright
                                    )
                                    .cornerRadius(4)
                                }
                                .frame(height: 150)
                                .chartYAxis {
                                    AxisMarks(position: .leading) { value in
                                        AxisGridLine()
                                        AxisValueLabel {
                                            if let amount = value.as(Double.self) {
                                                Text(amount.toCompactCurrencyString())
                                                    .font(.system(size: 11))
                                            }
                                        }
                                    }
                                }
                                .chartXAxis {
                                    AxisMarks(position: .bottom) { _ in
                                        AxisValueLabel()
                                            .font(.system(size: 11, weight: .medium))
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .background(AppColors.inputBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        
                        // MARK: - Recent Transactions
                        VStack(spacing: 18) {
                            HStack {
                                Text("Recent Transactions")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(AppColors.textPrimary)
                                
                                Spacer()
                                
                                Button {
                                    onSeeAllTapped()
                                } label: {
                                    Text("See All")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(AppColors.primary)
                                }
                            }
                            
                            if viewModel.recentTransactions.isEmpty {
                                Text("No recent transactions")
                                    .font(.system(size: 14))
                                    .foregroundStyle(AppColors.textSecondary)
                                    .padding(.top, 16)
                            } else {
                                VStack(spacing: 10) {
                                    ForEach(viewModel.recentTransactions) { tx in
                                        TransactionRowView(transaction: tx)
                                            .padding(.trailing, 12)
                                            .padding(.vertical, 6)
                                            .background(AppColors.inputBackground)
                                            .clipShape(RoundedRectangle(cornerRadius: 24))
                                    }
                                }
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.updateData(from: transactionsViewModel.transactions)
            }
            .onChange(of: transactionsViewModel.transactions) { oldValue, newValue in
                viewModel.updateData(from: newValue)
            }
        }
    }
}

#Preview {
    HomeScreen(
        transactionsViewModel: TransactionsViewModel(),
        onSeeAllTapped: {print("Abv")}
    )
    .environmentObject(UserManager())
}
