//
//  EditProfileSheet.swift
//  RandumApp
//
//  Created by dannyduy on 8/10/26.
//
import SwiftUI

struct EditProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    @State private var name: String
    @State private var age: String
    @State private var gender: Gender
    
    @State private var debouncedAgeError: String? = nil
    @State private var ageValidationTask: Task<Void, Never>? = nil
    
    var onSave: (User) -> Void
    
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
    
    init(user: User, onSave: @escaping (User) -> Void) {
        _name = State(initialValue: user.name)
        _age = State(initialValue: "\(user.age)")
        _gender = State(initialValue: user.gender)
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.currentAccent.backgroundColor
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 6) {
                        // MARK: - Name Field with Counter
                        VStack(alignment: .trailing, spacing: 4) {
                            AuthTextField(title: "Full Name", text: $name)
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
                        VStack(alignment: .leading) {
                            HStack(alignment: .top, spacing: 10) {
                                // Age Field
                                AuthTextField(title: "Age", text: $age)
                                    .keyboardType(.numberPad)
                                    .onChange(of: age) { _, newValue in
                                        let filtered = newValue.filter { $0.isNumber }
                                        if filtered.count > 3 {
                                            age = String(filtered.prefix(3))
                                        } else {
                                            age = filtered
                                        }
                                        triggerAgeDebounceValidation(for: age)
                                    }
                                
                                // Gender Menu Dropdown
                                genderPickerMenu
                            }
                            
                            // Age Error Feedback Message
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
                        .animation(.easeInOut(duration: 0.2), value: debouncedAgeError)
                        
                        Spacer()
                        
                        // MARK: - Submit Button
                        AppButton(
                            title: "Save Changes",
                            isDisabled: !isFormValid,
                            isLoading: false,
                            action: saveAndDismiss
                        )
                    }
                    .padding(16)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Edit Profile")
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
        .tint(themeManager.currentAccent.primaryColor)
    }
    
    // MARK: - Subview: Gender Dropdown Menu
    private var genderPickerMenu: some View {
        Menu {
            Picker("Gender", selection: $gender) {
                ForEach(Gender.allCases) { g in
                    Text(g.displayName).tag(g)
                }
            }
        } label: {
            HStack {
                Text(gender.displayName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColors.textSecondary)
            }
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(themeManager.currentAccent.inputBackgroundColor)
            .contentShape(Capsule())
            .clipShape(Capsule())
        }
    }
    
    // MARK: - Debounce Age Validation
    private func triggerAgeDebounceValidation(for input: String) {
        ageValidationTask?.cancel()
        
        let rawAge = input.trimmingCharacters(in: .whitespaces)
        if rawAge.isEmpty {
            debouncedAgeError = nil
            return
        }
        
        ageValidationTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
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
    
    // MARK: - Action: Save
    private func saveAndDismiss() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        guard let validAge = parsedAge, isFormValid else { return }
        
        let updatedUser = User(
            name: trimmedName,
            age: validAge,
            gender: gender
        )
        onSave(updatedUser)
        dismiss()
    }
}

#Preview {
    EditProfileSheet(
        user: User(
            name: "Duy Hoang Thanh",
            age: 22,
            gender: .male
        ),
        onSave: { updatedUser in
            print("Saved user: \(updatedUser.name)")
        }
    )
}

