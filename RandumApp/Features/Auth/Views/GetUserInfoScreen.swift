//
//  GetUserInfoScreen.swift
//  RandumApp
//
//  Created by dannyduy on 3/10/26.
//

import SwiftUI

struct GetUserInfoScreen: View {
    var onComplete: (User) -> Void
    
    @State private var name: String = ""
    @State private var age: String = ""
    @State private var selectedGender: Gender = .male
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !age.trimmingCharacters(in: .whitespaces).isEmpty &&
        (Int(age) != nil)
    }
    
    var body: some View {
        GeometryReader { geometry in
            let screenHeight = geometry.size.height
            
            ZStack (alignment: .top) {
                // Banner
                ZStack {
                    AppColors.primary
                        .ignoresSafeArea()
                    
                    VStack(){
                        Spacer()
                        
                        ZStack{
                            // Blur Card Behind
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.white.opacity(0.12))
                                .frame(width: 320, height: 260)
                                .rotationEffect(.degrees(12))
                            
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.white.opacity(0.16))
                                .frame(width: 320, height: 260)
                                .rotationEffect(.degrees(6))
                            
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.white.opacity(0.2))
                                .frame(width: 320, height: 260)
                                .overlay(
                                    Image(systemName: "person.crop.circle.badge.plus")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 152, height: 152)
                                        .foregroundStyle(.white)
                                )
                                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        }
                        
                        Spacer()
                    }
                    .padding(.bottom, screenHeight * 0.05)
                }
                .frame(width: geometry.size.width, height: screenHeight * 0.6)
                
                // Form
                VStack(alignment: .center, spacing: 10){
                    Spacer()
                    
                    Text("Profile Setup")
                        .font(.system(size: 30, weight: .heavy))
                        .tracking(2)
                        .foregroundStyle(AppColors.primary)
                    
                    Text("Tell Us About You")
                        .font(.system(size: 25, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text( "Please fill in your personal details to personalize your financial tracking.")
                        .font(.system(size: 15))
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Spacer()
                    
                    VStack(spacing: 12) {
                        // Name
                        AuthTextField(
                            title: "Full Name",
                            text: $name
                        )
                        
                        HStack(spacing: 10) {
                            // Age
                            AuthTextField(
                                title: "Age",
                                text: $age
                            )
                            .keyboardType(.numberPad)
                            .frame(maxWidth: geometry.size.width * 0.35)
                            
                            // Gender
                            Menu {
                                ForEach(Gender.allCases) { gender in
                                    Button(action: {
                                        selectedGender = gender
                                    }) {
                                        HStack {
                                            Text(gender.displayName)
                                            if selectedGender == gender {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(selectedGender.displayName)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(AppColors.textPrimary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(AppColors.textSecondary)
                                }
                                .padding(.horizontal, 18)
                                .frame(height: 52)
                                .frame(maxWidth: .infinity)
                                .background(AppColors.inputBackground)
                                .clipShape(Capsule())
                            }
                        }
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 12) {
                        AppButton(
                            title: "Continue",
                            isDisabled: !isFormValid,
                            isLoading: false,
                            action: {
                                saveAndProceed()
                            }
                        )
                        
                        Text("Your information is stored safely on your device.")
                            .font(.system(size: 12))
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 24)
                .padding(.bottom, 30)
                .frame(width: geometry.size.width, height: screenHeight * 0.46)
                .background(
                    Color(.systemBackground)
                        .cornerRadiusTop(36)
                )
                .offset(y: screenHeight * 0.5)
            }
        }
        .ignoresSafeArea(.all)
    }
    
    private func saveAndProceed() {
        guard let validAge = Int(age), isFormValid else { return }
        
        let newUser = User(
            name: name.trimmingCharacters(in: .whitespaces),
            age: validAge,
            gender: selectedGender
        )
        
        UserDefaults.standard.savedUser = newUser
        
        onComplete(newUser)
    }
}

#Preview {
    GetUserInfoScreen(onComplete: { user in
        print("User registered: \(user.name)")
    })
}
