//
//  AuthTextField.swift
//  RandumApp
//
//  Created by dannyduy on 1/10/26.
//

import SwiftUI

struct AuthTextField: View {
    let title: String
    @Binding var text: String
    var systemImage: String? = nil
    var isDisabled: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Leading Icon
            if let systemImage = systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 16))
                    .foregroundStyle(isDisabled ? AppColors.textSecondary.opacity(0.6) : AppColors.textSecondary)
                    .frame(width: 20)
            }
            
            // Placeholder TextField
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(title)
                        .font(.system(size: 15))
                        .foregroundStyle(AppColors.textSecondary)
                }
                
                TextField("", text: $text)
                    .font(.system(size: 15))
                    .foregroundStyle(isDisabled ? AppColors.textSecondary : AppColors.textPrimary)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .disabled(isDisabled)
            }
            
            // Clear Button
            if !text.isEmpty && !isDisabled {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(AppColors.textSecondary)
                }
                .buttonStyle(.plain)
            }
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
    @Previewable @State var sampleText = ""
    
    VStack {
        AuthTextField(title: "Enter here...", text: $sampleText)
        AuthTextField(title: "Email cố định", text: $sampleText, isDisabled: true)
    }
    .padding()
}
