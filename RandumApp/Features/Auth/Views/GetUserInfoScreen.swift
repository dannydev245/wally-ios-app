//
//  GetUserInfoScreen.swift
//  RandumApp
//
//  Created by dannyduy on 3/10/26.
//

import SwiftUI

struct GetUserInfoScreen: View {
    var onComplete: (User) -> Void
    @ObservedObject private var themeManager = ThemeManager.shared
    
    @State private var name: String = ""
    @State private var age: String = ""
    @State private var selectedGender: Gender = .male
    
    // State for debouncedAgeError
    @State private var debouncedAgeError: String? = nil
    @State private var ageValidationTask: Task<Void, Never>? = nil
    
    private let maxNameLength = 30
    private let minAge = 10
    private let maxAge = 120
    
    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespaces)
    }
    
    private var isNameValid: Bool {
        trimmedName.count >= 2 && trimmedName.count <= maxNameLength
    }
    
    private var parsedAge: Int? {
        Int(age.trimmingCharacters(in: .whitespaces))
    }
    
    private var isAgeValid: Bool {
        if let val = parsedAge {
            return val >= minAge && val <= maxAge
        }
        return false
    }
    
    private var isFormValid: Bool {
        isNameValid && isAgeValid
    }
    
    var body: some View {
        GeometryReader { geometry in
            let screenHeight = geometry.size.height
            let screenWidth = geometry.size.width
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: -32) { // Kéo Card bo tròn phủ đè lên chân banner chuẩn layout
                    topBannerSection(height: max(screenHeight * 0.56, 300), safeTop: geometry.safeAreaInsets.top)
                    bottomFormSection(screenWidth: screenWidth)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(Color(.systemBackground))
        .ignoresSafeArea(.all, edges: .top)
    }
    
    // MARK: - Subview: Banner Section
    private func topBannerSection(height: CGFloat, safeTop: CGFloat) -> some View {
        ZStack {
            themeManager.currentAccent.primaryColor
                .frame(maxWidth: .infinity)
                .frame(height: height)
            
            VStack {
                Spacer()
                
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.white.opacity(0.12))
                        .frame(width: 300, height: 230)
                        .rotationEffect(.degrees(12))
                    
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.white.opacity(0.16))
                        .frame(width: 300, height: 230)
                        .rotationEffect(.degrees(6))
                    
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.white.opacity(0.20))
                        .frame(width: 300, height: 230)
                        .overlay(
                            Image(systemName: "person.crop.circle.badge.plus")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 120, height: 120)
                                .foregroundStyle(.white)
                        )
                        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 5)
                }
                
                Spacer()
            }
            .padding(.top, safeTop > 0 ? safeTop : 16)
            .padding(.bottom, 24)
        }
    }
    
    // MARK: - Subview: Form Section
    private func bottomFormSection(screenWidth: CGFloat) -> some View {
        VStack(alignment: .center, spacing: 18) {
            // Header Typography
            VStack(spacing: 6) {
                Text("Profile Setup")
                    .font(.system(size: 28, weight: .heavy))
                    .tracking(2)
                    .foregroundStyle(themeManager.currentAccent.primaryColor)
                
                Text("Tell Us About You")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                
                Text("Please fill in your personal details to personalize your financial tracking.")
                    .font(.system(size: 14))
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 8)
            }
            
            // Input Controls
            VStack(spacing: 6) {
                // MARK: - Name Field with Counter
                VStack(alignment: .trailing, spacing: 4){
                    AuthTextField(
                        title: "Full Name",
                        text: $name
                    )
                    .onChange(of: name) { _, newValue in
                        if newValue.count > maxNameLength {
                            name = String(newValue.prefix(maxNameLength))
                        }
                    }
                    
                    Text("\(name.count)/\(maxNameLength)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(name.count >= maxNameLength ? Color.red : AppColors.textSecondary)
                        .padding(.trailing, 12)
                }
                
                // MARK: - Age & Gender Row
                VStack(alignment: .leading){
                    HStack(alignment: .top, spacing: 10) {
                        // Age Field
                        VStack(alignment: .leading, spacing: 4){
                            AuthTextField(
                                title: "Age",
                                text: $age
                            )
                            .keyboardType(.numberPad)
                            .frame(maxWidth: screenWidth * 0.35)
                            .onChange(of: age) { _, newValue in
                                // max 3 charactor
                                let filtered = newValue.filter { $0.isNumber }
                                if filtered.count > 3 {
                                    age = String(filtered.prefix(3))
                                } else {
                                    age = filtered
                                }
                                triggerAgeDebounceValidation(for: age)
                            }
                        }
                        // Gender Dropdown Menu
                        genderPickerMenu
                    }
                    
                    // MARK: - Age Error Feedback Message
                    if let error = debouncedAgeError {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 11))
                            Text(error)
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundStyle(Color.red.opacity(0.85))
                        .padding(.leading, 8)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
            .animation(.easeInOut(duration: 0.2), value: debouncedAgeError)
            
            // Submit Action
            VStack(spacing: 10) {
                AppButton(
                    title: "Continue",
                    isDisabled: !isFormValid,
                    isLoading: false,
                    action: saveAndProceed
                )
                
                Text("Your information is stored safely on your device.")
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .padding(.horizontal, 28)
        .padding(.top, 30)
        .frame(maxWidth: .infinity)
        .background(
            Color(.systemBackground)
                .cornerRadiusTop(36)
                .shadow(color: .black.opacity(0.06), radius: 10, y: -4)
        )
    }
    
    // MARK: - Subview: Gender Dropdown Menu
    private var genderPickerMenu: some View {
        Menu {
            ForEach(Gender.allCases) { gender in
                Button {
                    selectedGender = gender
                } label: {
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
            .background(themeManager.currentAccent.inputBackgroundColor)
            .clipShape(Capsule())
        }
    }
    
    // MARK: - Logic Debounce Validation
    private func triggerAgeDebounceValidation(for input: String) {
        // Cancel old task if user is typing
        ageValidationTask?.cancel()
        
        let rawAge = input.trimmingCharacters(in: .whitespaces)
        
        // if clear input -> hide message
        if rawAge.isEmpty {
            debouncedAgeError = nil
            return
        }
        
        // Create task waiting
        ageValidationTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
            
            // check if task is cancel by user typing
            if Task.isCancelled { return }
            
            await MainActor.run {
                if let val = Int(rawAge) {
                    if val < minAge || val > maxAge {
                        self.debouncedAgeError = "Age must be between \(minAge) and \(maxAge)"
                    } else {
                        self.debouncedAgeError = nil
                    }
                } else {
                    self.debouncedAgeError = "Invalid number"
                }
            }
        }
    }
    
    // MARK: - Actions
    private func saveAndProceed() {
        // close key board
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
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
