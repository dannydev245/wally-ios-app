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
    var systemImage: String? = "lock"
    var isNewPassword: Bool = false
    var isDisabled: Bool = false
    
    @State private var isVisible = false
    
    var body: some View {
        HStack(spacing: 12){
            // Leading Icon
            if let systemImage = systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 16))
                    .foregroundStyle(isDisabled ? AppColors.textSecondary.opacity(0.6) : AppColors.textSecondary)
                    .frame(width: 20)
            }
            
            // Password Input Area
            ZStack(alignment: .leading) {
                // Placeholder
                if password.isEmpty {
                    Text(title)
                        .font(.system(size: 15))
                        .foregroundStyle(AppColors.textSecondary)
                }
                
                SecureField("", text: $password)
                    .font(.system(size: 15))
                    .foregroundStyle(isDisabled ? AppColors.textSecondary : AppColors.textPrimary)
                    .textContentType(isNewPassword ? .newPassword : .password)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .disabled(isDisabled)
                    .opacity(isVisible ? 0 : 1)
                
                TextField("", text: $password)
                    .font(.system(size: 15))
                    .foregroundStyle(isDisabled ? AppColors.textSecondary : AppColors.textPrimary)
                    .textContentType(isNewPassword ? .newPassword : .password)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .disabled(isDisabled)
                    .opacity(isVisible ? 1 : 0)
            }
            
            // Toggle hide/show Password
            Button {
                isVisible.toggle()
            } label: {
                Image(systemName: isVisible ? "eye" : "eye.slash")
                    .font(.system(size: 16))
                    .foregroundStyle(AppColors.textSecondary)
            }
            .buttonStyle(AppPressableButtonStyle())
            .accessibilityLabel(isVisible ? "Hide password" : "Show password")
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
    }
}

#Preview {
    @Previewable @State var password = ""
    @Previewable @State var disabledPassword = "secretPassword123"
    
    VStack(spacing: 16) {
        PasswordField(title: "Password", password: $password)
        PasswordField(title: "Disabled Password", password: $disabledPassword, isDisabled: true)
    }
    .padding()
    .background(AppColors.background)
}
