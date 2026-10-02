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
    var isDisabled: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            TextField(title, text: $text)
                .font(.system(size: 14))
                .autocorrectionDisabled()
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
        AuthTextField(title: "Enter here...", text: $sampleText)
        AuthTextField(title: "Email cố định", text: $sampleText, isDisabled: true)
    }
    .padding()
}
