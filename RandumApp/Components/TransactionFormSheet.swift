//
//  TransactionFormSheet.swift
//  RandumApp
//
//  Created by dannyduy on 4/10/26.
//

import SwiftUI

struct TransactionFormSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var transactionToEdit: TransactionItem? = nil
    var onSave: (String, Double, Date, TransactionType, TransactionCategory) -> Void
    
    @State private var selectedType: TransactionType = .expense
    @State private var title: String = ""
    @State private var amountString: String = ""
    @State private var selectedCategory: TransactionCategory = .shopping
    @State private var selectedDate: Date = Date()
    @State private var pickerId = UUID()
    
    init(
        transactionToEdit: TransactionItem? = nil,
        onSave: @escaping (String, Double, Date, TransactionType, TransactionCategory) -> Void
    ) {
        self.transactionToEdit = transactionToEdit
        self.onSave = onSave
        
        if let item = transactionToEdit {
            _selectedType = State(initialValue: item.type)
            _title = State(initialValue: item.title)
            _amountString = State(initialValue: String(Int(item.amount)))
            _selectedCategory = State(initialValue: item.category)
            _selectedDate = State(initialValue: item.date)
        }
    }
    
    private var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        (Double(amountString) ?? 0) > 0
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // MARK: - Header Type Selection (Expense default)
                        HStack(alignment: .center) {
                            ForEach(TransactionType.allCases) { type in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedType = type
                                        // Reset category
                                        selectedCategory = TransactionCategory.categories(for: type).first ?? .other
                                    }
                                } label: {
                                    Text(type.rawValue)
                                        .font(.system(size: 15, weight: .bold))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(selectedType == type ? AppColors.primary : AppColors.inputBackground)
                                        .foregroundStyle(selectedType == type ? .white : AppColors.textPrimary)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }
                        
                        // MARK: - Form Inputs
                        VStack(alignment: .center, spacing: 12) {
                            // Title Input
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Transaction Name")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(AppColors.textPrimary)
                                
                                TextField("e.g. Lunch with friends", text: $title)
                                    .padding()
                                    .background(AppColors.inputBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .foregroundStyle(AppColors.textPrimary)
                            }
                            
                            // Amount
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Amount (\(themeManager.currentCurrency == .vnd ? "VND" : "USD")")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(AppColors.textPrimary)
                                
                                HStack {
                                    TextField("0", text: $amountString)
                                        .keyboardType(.numberPad)
                                        .foregroundStyle(AppColors.textPrimary)
                                    
                                    Text(themeManager.currentCurrency.symbol)
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(AppColors.textSecondary)
                                }
                                .padding()
                                .background(AppColors.inputBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            
                            GeometryReader { proxy in
                                let spacing: CGFloat = 12
                                let availableWidth = proxy.size.width - spacing
                                let categoryWidth = availableWidth * (2.0 / 3.0)
                                let dateWidth = availableWidth * (1.0 / 3.0)
                                
                                HStack(spacing: spacing) {
                                    // MARK: - Category Selection (2/3 Width)
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Category")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundStyle(AppColors.textPrimary)
                                        
                                        Menu {
                                            ForEach(TransactionCategory.categories(for: selectedType)) { category in
                                                Button {
                                                    selectedCategory = category
                                                } label: {
                                                    HStack {
                                                        if selectedCategory == category {
                                                            Label(
                                                                category.rawValue,
                                                                systemImage: "checkmark"
                                                            )
                                                        } else {
                                                            Label(
                                                                category.rawValue,
                                                                systemImage: category.iconName
                                                            )
                                                        }
                                                    }
                                                }
                                            }
                                        } label: {
                                            HStack(spacing: 8) {
                                                Image(systemName: selectedCategory.iconName)
                                                    .font(.system(size: 14))
                                                    .foregroundStyle(AppColors.textPrimary)
                                                
                                                Text(selectedCategory.rawValue)
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundStyle(AppColors.textPrimary)
                                                    .lineLimit(1)
                                                
                                                Spacer(minLength: 0)
                                                
                                                Image(systemName: "chevron.down")
                                                    .font(.system(size: 12, weight: .semibold))
                                                    .foregroundStyle(AppColors.textSecondary)
                                            }
                                            .padding(.horizontal, 12)
                                            .frame(maxWidth: .infinity, minHeight: 48)
                                            .background(AppColors.inputBackground)
                                            .contentShape(Rectangle())
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                        }
                                    }
                                    .frame(width: categoryWidth, alignment: .leading)
                                    
                                    // MARK: - Date Picker (1/3 width)
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Date")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundStyle(AppColors.textPrimary)
                                        
                                        ZStack {
                                            HStack(spacing: 6) {
                                                Image(systemName: "calendar")
                                                    .font(.system(size: 14))
                                                    .foregroundStyle(AppColors.textSecondary)
                                                
                                                Text(selectedDate.formatted(date: .abbreviated, time: .omitted))
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundStyle(AppColors.textPrimary)
                                                    .lineLimit(1)
                                            }
                                            DatePicker("", selection: $selectedDate, in: ...Date(), displayedComponents: [.date])
                                                .id(pickerId)
                                                .datePickerStyle(.compact)
                                                .labelsHidden()
                                                .colorMultiply(.clear)
                                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                                .opacity(0.015)
                                                .contentShape(Rectangle())
                                                .onChange(of: selectedDate) {
                                                    pickerId = UUID()
                                                }
                                        }
                                        .frame(maxWidth: .infinity, minHeight: 48)
                                        .background(AppColors.inputBackground)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                    .frame(width: dateWidth, alignment: .leading)
                                }
                            }
                            .frame(height: 46)
                        }
                        
                        Spacer()
                        
                        // MARK: - Action Button
                        Button {
                            guard let amount = Double(amountString), isFormValid else { return }
                            onSave(title.trimmingCharacters(in: .whitespaces), amount, selectedDate, selectedType, selectedCategory)
                            dismiss()
                        } label: {
                            Text(transactionToEdit == nil ? "Create Transaction" : "Update Transaction")
                                .font(.system(size: 16, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(isFormValid ? AppColors.primary : Color.gray.opacity(0.3))
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .disabled(!isFormValid)
                    }
                    .padding(.top, 10)
                    .padding(.horizontal, 20)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle(transactionToEdit == nil ? "New Transaction" : "Edit Transaction")
            .navigationBarTitleDisplayMode(.inline)
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
    }
}

#Preview {
    TransactionFormSheet(transactionToEdit: nil, onSave: {title, amount, date, type, category in
        print()
    })
}
