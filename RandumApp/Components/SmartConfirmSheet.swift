//
//  SmartConfirmSheet.swift
//  RandumApp
//
//  Created by dannyduy on 27/10/26.
//

import SwiftUI

struct SmartConfirmSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var themeManager = ThemeManager.shared
    
    @State var parsedResult: ParsedTransactionResult
    var onConfirm: (ParsedTransactionResult) -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Tiêu đề & Icon gợi ý
                VStack(alignment: .center, spacing: 6) {
                    HStack(spacing: 8) {
                        Text("Transaction Detected")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(AppColors.textPrimary)
                        
                        Text("Auto")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(themeManager.currentAccent.primaryColor)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(themeManager.currentAccent.primaryColor.opacity(0.12))
                            )
                    }
                    
                    Text("Verify the details below before saving")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                
                // Form hiển thị nhanh
                VStack(spacing: 14) {
                    // Tiêu đề
                    HStack {
                        Text("Title")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.textSecondary)
                        Spacer()
                        TextField("Title", text: $parsedResult.title)
                            .multilineTextAlignment(.trailing)
                            .fontWeight(.medium)
                    }
                    
                    Divider()
                    
                    // Số tiền
                    HStack {
                        Text("Amount (\(themeManager.currentCurrency == .vnd ? "VND" : "USD"))")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.textSecondary)
                        Spacer()
                        HStack {
                            TextField("0", value: $parsedResult.amount, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .fontWeight(.bold)
                                .foregroundStyle(themeManager.currentAccent.primaryColor)
                            Text(themeManager.currentCurrency.symbol)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(themeManager.currentAccent.primaryColor)
                        }
                    }
                    
                    Divider()
                    
                    // Danh mục
                    HStack {
                        Text("Category")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.textSecondary)
                        Spacer()
                        Picker("Category", selection: $parsedResult.category) {
                            ForEach(TransactionCategory.allCases, id: \.self) { cat in
                                Text(cat.rawValue.capitalized).tag(cat)
                            }
                        }
                        .tint(themeManager.currentAccent.primaryColor)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(themeManager.currentAccent.inputBackgroundColor)
                )
                                
                // Nút Xác nhận Lưu
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onConfirm(parsedResult)
                    dismiss()
                } label: {
                    Text("Confirm & Save")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(themeManager.currentAccent.primaryColor)
                        )
                }
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Label("Cancel", systemImage: "multiply")
                    }
                }
            }
        }
        .tint(themeManager.currentAccent.primaryColor)
    }
}
