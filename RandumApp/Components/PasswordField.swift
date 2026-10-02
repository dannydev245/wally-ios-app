//
//  PasswordField.swift
//  RandumApp
//
//  Created by dannyduy on 2/10/26.
//

import SwiftUI

struct PasswordField: View {
    let title: String
    @Binding var password: String
    var isDisabled: Bool = false
    
    @State private var isVisible = false
    
    var body: some View {
        HStack(spacing: 12){
            Group {
                if isVisible {
                    TextField(title, text: $password)
                } else {
                    SecureField(title, text: $password)
                }
            }
            .font(.system(size: 14))
            .textContentType(.newPassword)
            .autocorrectionDisabled()
            .disabled(isDisabled)
            
            Button{
                isVisible.toggle()
            } label: {
                Image(
                    systemName: isVisible
                    ? "eye"
                    : "eye.slash"
                )
                .foregroundStyle(AppColors.textSecondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                isVisible ? "Hide password" : "Show password"
            )
            .disabled(isDisabled)
        }
        .padding(.horizontal, 18)
        .frame(height: 52)
        .background(
            isDisabled
            ? AppColors.inputBackground.opacity(0.5)
            : AppColors.inputBackground
        )
        .clipShape(Capsule())
        .foregroundColor(isDisabled ? AppColors.textSecondary : AppColors.textPrimary)
    }
}

#Preview {
    @Previewable @State var sampleText = ""
    
    VStack {
        PasswordField(title: "Enter here...", password: $sampleText)
    }
    .padding()
}
