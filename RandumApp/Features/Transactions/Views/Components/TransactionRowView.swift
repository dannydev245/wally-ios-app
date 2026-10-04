//
//  TransactionRowView.swift
//  RandumApp
//
//  Created by dannyduy on 4/10/26.
//

import SwiftUI

struct TransactionRowView: View {
    let transaction: TransactionItem
    
    var body: some View {
        HStack(spacing: 14) {
            // Category Icon
            Image(systemName: transaction.category.iconName)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(transaction.type == .income ? Color.green : AppColors.primary)
                .frame(width: 54, height: 54)
                .background(AppColors.inputBackground)
                .clipShape(Circle())
            
            // Title & Category
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
                
                Text(transaction.category.rawValue)
                    .font(.system(size: 14))
                    .foregroundStyle(AppColors.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                // Date
                Text(transaction.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 14))
                    .foregroundStyle(AppColors.textSecondary)
                
                // Amount formatted in VND
                Text("\(transaction.type == .income ? "+" : "-")\(Int(transaction.amount).formatted()) ₫")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(transaction.type == .income ? Color.green : Color.red)
            }
            
        }
    }
}

#Preview {
    TransactionRowView(transaction: TransactionItem(id: UUID(), title: "Purchase Item", amount: 3000000, date: Date(), type: .expense, category: .investment))
}
