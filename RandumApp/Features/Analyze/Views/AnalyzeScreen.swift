//
//  AnalyzeScreen.swift
//  RandumApp
//
//  Created by dannyduy on 3/10/26.
//

import SwiftUI
import Charts

struct AnalyzeScreen: View {
    @ObservedObject var transactionsViewModel: TransactionsViewModel
    @StateObject private var viewModel = AnalyzeViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .center, spacing: 20) {
                        // MARK: - Scope Segment Picker (Day / Week / Month / Year)
                        HStack(alignment: .center, spacing: 0) {
                            ForEach(TimeScope.allCases) { scope in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        viewModel.selectedScope = scope
                                        viewModel.updateAnalytics(from: transactionsViewModel.transactions)
                                    }
                                } label: {
                                    Text(scope.rawValue)
                                        .font(.system(size: 14, weight: .semibold))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(viewModel.selectedScope == scope ? AppColors.primary : Color.clear)
                                        .foregroundStyle(viewModel.selectedScope == scope ? .white : AppColors.textSecondary)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }
                        .padding(4)
                        .background(AppColors.inputBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        
                        // MARK: - Date Switcher (< Month/Year >)
                        HStack {
                            Button {
                                withAnimation {
                                    viewModel.movePeriod(by: -1)
                                    viewModel.updateAnalytics(from: transactionsViewModel.transactions)
                                }
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(AppColors.textPrimary)
                                    .padding(10)
                                    .background(AppColors.inputBackground)
                                    .clipShape(Circle())
                            }
                            
                            Spacer()
                            
                            Text(viewModel.periodTitle)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(AppColors.textPrimary)
                            
                            Spacer()
                            
                            Button {
                                withAnimation {
                                    viewModel.movePeriod(by: 1)
                                    viewModel.updateAnalytics(from: transactionsViewModel.transactions)
                                }
                            } label: {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(AppColors.textPrimary)
                                    .padding(10)
                                    .background(AppColors.inputBackground)
                                    .clipShape(Circle())
                            }
                        }
                        
                        // MARK: - Period Summary Card
                        VStack(spacing: 14) {
                            VStack(spacing: 4) {
                                Text("Net Cash Flow")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(AppColors.textSecondary)
                                
                                Text(viewModel.netFlow.toCurrencyString())
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundStyle(viewModel.netFlow >= 0 ? AppColors.greenEmerald : AppColors.redBright)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
                            
                            Divider()
                                .background(AppColors.textSecondary.opacity(0.2))
                            
                            HStack(alignment: .center, spacing: 12) {
                                // Income
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.down.left.circle.fill")
                                        .font(.system(size: 30))
                                        .foregroundStyle(AppColors.greenEmerald)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Income")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundStyle(AppColors.textSecondary)
                                        Text(viewModel.periodIncome.toCurrencyString())
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundStyle(AppColors.greenEmerald)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.65)
                                            .allowsTightening(true)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                                // Expense
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.up.right.circle.fill")
                                        .font(.system(size: 30))
                                        .foregroundStyle(AppColors.redBright)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Expense")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundStyle(AppColors.textSecondary)
                                        Text(viewModel.periodExpense.toCurrencyString())
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundStyle(AppColors.redBright)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.65)
                                            .allowsTightening(true)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(16)
                        .background(AppColors.inputBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        
                        // MARK: - Dynamic Scope Chart
                        VStack(alignment: .leading, spacing: 18) {
                            HStack {
                                Text("Cash Flow Chart")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(AppColors.textPrimary)
                                Spacer()
                                
                                HStack(spacing: 12) {
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(AppColors.greenEmerald)
                                            .frame(width: 7, height: 7)
                                        Text("Income")
                                            .font(.system(size: 11))
                                            .foregroundStyle(AppColors.textSecondary)
                                    }
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(AppColors.redBright)
                                            .frame(width: 7, height: 7)
                                        Text("Expense")
                                            .font(.system(size: 11))
                                            .foregroundStyle(AppColors.textSecondary)
                                    }
                                }
                            }
                            
                            if viewModel.chartData.allSatisfy({ $0.amount == 0 }) {
                                Text("No transactions recorded for this period.")
                                    .font(.system(size: 13))
                                    .foregroundStyle(AppColors.textSecondary)
                                    .frame(maxWidth: .infinity, minHeight: 160)
                            } else {
                                Chart(viewModel.chartData) { item in
                                    BarMark(
                                        x: .value("Interval", item.label),
                                        y: .value("Amount", item.amount)
                                    )
                                    .position(by: .value("Type", item.type.rawValue))
                                    .foregroundStyle(item.type == .income ? AppColors.greenEmerald : AppColors.redBright)
                                    .cornerRadius(3)
                                }
                                .frame(height: 180)
                                .chartYAxis {
                                    AxisMarks(position: .leading) { val in
                                        AxisGridLine()
                                        AxisValueLabel {
                                            if let amt = val.as(Double.self) {
                                                Text(amt.toCompactCurrencyString())
                                                    .font(.system(size: 9))
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
                        
                        // MARK: - Category Spending Breakdown
                        VStack(alignment: .leading, spacing: 18) {
                            Text("Spending by Category")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(AppColors.textPrimary)
                            
                            if viewModel.categoryBreakdown.isEmpty {
                                Text("No expense categories in this period.")
                                    .font(.system(size: 13))
                                    .foregroundStyle(AppColors.textSecondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 20)
                            } else {
                                // MARK: - Donut Chart
                                ZStack {
                                    Chart(viewModel.categoryBreakdown) { item in
                                        SectorMark(
                                            angle: .value("Amount", item.totalAmount),
                                            innerRadius: .ratio(0.6),
                                            angularInset: 0.0 // gap between each sector
                                        )
                                        .cornerRadius(5)
                                        .foregroundStyle(by: .value("Category", item.category.rawValue))
                                    }
                                    .frame(height: 190)
                                    .chartLegend(.hidden)
                                    
                                    VStack(spacing: 2) {
                                        Text("Total")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundStyle(AppColors.textSecondary)
                                        
                                        Text(viewModel.periodExpense.toCompactCurrencyString())
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundStyle(AppColors.textPrimary)
                                    }
                                }
                                .padding(.vertical, 6)
                                
                                Divider()
                                    .background(AppColors.textSecondary.opacity(0.15))
                                
                                // MARK: - Category Breakdown List
                                VStack(spacing: 14) {
                                    ForEach(viewModel.categoryBreakdown) { item in
                                        VStack(spacing: 6) {
                                            HStack {
                                                Label(item.category.rawValue, systemImage: item.category.iconName)
                                                    .font(.system(size: 16, weight: .medium))
                                                    .foregroundStyle(AppColors.textPrimary)
                                                Spacer()
                                                Text(item.totalAmount.toCurrencyString())
                                                    .font(.system(size: 16, weight: .bold))
                                                    .foregroundStyle(AppColors.textPrimary)
                                                Text(String(format: "(%.0f%%)", item.percentage * 100))
                                                    .font(.system(size: 14))
                                                    .foregroundStyle(AppColors.textSecondary)
                                            }
                                            
                                            // Progress Bar
                                            GeometryReader { proxy in
                                                ZStack(alignment: .leading) {
                                                    Capsule()
                                                        .fill(AppColors.textSecondary.opacity(0.15))
                                                        .frame(height: 6)
                                                    
                                                    Capsule()
                                                        .fill(AppColors.primary)
                                                        .frame(width: proxy.size.width * CGFloat(item.percentage), height: 6)
                                                }
                                            }
                                            .frame(height: 8)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .background(AppColors.inputBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                }
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                viewModel.updateAnalytics(from: transactionsViewModel.transactions)
            }
            .onChange(of: transactionsViewModel.transactions) { oldValue, newValue in
                viewModel.updateAnalytics(from: newValue)
            }
        }
    }
}

#Preview {
    AnalyzeScreen(
        transactionsViewModel: TransactionsViewModel()
    )
}
