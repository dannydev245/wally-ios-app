//
//  AppButton.swift
//  RandumApp
//
//  Created by dannyduy on 1/10/26.
//

import SwiftUI

struct AppButton: View {
    let title: String
    var isDisabled: Bool
    var isLoading: Bool
    var action: (() -> Void)?
    
    init(
        title: String = "ButtonTitle",
        isDisabled: Bool = false,
        isLoading: Bool = false,
        action: (() -> Void)? = nil)
    {
        self.title = title
        self.isDisabled = isDisabled
        self.isLoading = isLoading
        self.action = action
    }
    
    var body: some View {
        let isButtonDisabled = isDisabled || isLoading
        
        Button(action: {
            action?()
        }){
            ZStack{
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .opacity(isLoading ? 0 : (isDisabled ? 0.7 : 1))
                
                if isLoading {
                    ProgressView()
                        .tint(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                isButtonDisabled
                ? AppColors.primary.opacity(0.4)
                : AppColors.primary
            )
            .clipShape(Capsule())
        }
        .disabled(isButtonDisabled)
        .buttonStyle(AppPressableButtonStyle())
    }
}


#Preview {
    VStack(spacing: 16) {
        AppButton(title: "Sign Up") {
            print("Button Pressed!")
        }
        //        AppButton(isLoading: true)
        AppButton(title: "Not yet eligible", isDisabled: true)
    }
    .padding()
    .background(.black)
}
