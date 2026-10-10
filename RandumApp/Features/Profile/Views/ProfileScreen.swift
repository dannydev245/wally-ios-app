//
//  ProfileScreen.swift
//  RandumApp
//
//  Created by dannyduy on 3/10/26.
//

import SwiftUI

struct ProfileScreen: View {
    @ObservedObject var transactionsViewModel: TransactionsViewModel
    var onLogout: () -> Void
    
    @EnvironmentObject private var userManager: UserManager
    @ObservedObject private var themeManager = ThemeManager.shared
    
    // Sheets & Alerts
    @State private var showEditProfileSheet = false
    @State private var showClearDataAlert = false
    @State private var showLogoutConfirmation = false
    @State private var shareURL: URL? = nil
    @State private var showShareSheet = false
    
    @State private var confirmClearText = ""
    @State private var confirmLogoutText: String = ""
    
    private var currentUser: User {
        userManager.currentUser ?? User(name: "User", age: 20, gender: .male)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.currentAccent.backgroundColor
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        userHeaderCard
                        appearanceThemeCard
                        dataPreferencesCard
                        dangerZoneCard
                    }
                    .padding(.horizontal, 16)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            
            // MARK: - Sheet: EditProfileSheet
            .sheet(isPresented: $showEditProfileSheet) {
                EditProfileSheet(user: currentUser) { updatedUser in
                    userManager.updateUser(updatedUser)
                }
                .presentationDetents([.fraction(0.68),.large])
                .presentationDragIndicator(.visible)
            }
            
            // MARK: - Alert: Clear All Transactions
            .alert("Clear All Transactions?", isPresented: $showClearDataAlert) {
                TextField("Type 'CLEAR' to confirm", text: $confirmClearText)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                
                Button("Clear All", role: .destructive) {
                    if confirmClearText.uppercased() == "CLEAR" {
                        transactionsViewModel.clearAllTransactions()
                    }
                    confirmClearText = ""
                }
                .disabled(confirmClearText.uppercased() != "CLEAR")
                
                Button("Cancel", role: .cancel) {
                    confirmClearText = ""
                }
            } message: {
                Text("This action is permanent and cannot be undone. Please type CLEAR below to proceed.")
            }
            
            // MARK: - Confirmation: Log Out
            .alert(
                "Are you sure you want to log out?",
                isPresented: $showLogoutConfirmation
            ) {
                TextField("Type 'LOGOUT' to confirm", text: $confirmLogoutText)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                
                Button("Log Out & Wipe Data", role: .destructive) {
                    if confirmLogoutText.trimmingCharacters(in: .whitespaces).uppercased() == "LOGOUT" {
                        confirmLogoutText = ""
                        onLogout()
                    }
                }
                .disabled(confirmLogoutText.trimmingCharacters(in: .whitespaces).uppercased() != "LOGOUT")
                
                Button("Cancel", role: .cancel) {
                    confirmLogoutText = ""
                }
            } message: {
                Text("This action is permanent and will wipe all recorded transactions and remove your user session. Please type LOGOUT to proceed.")
            }
            
            // MARK: - Sheet: Chia sẻ CSV (Dùng ActivityView từ Utils/UIHelpers)
            .sheet(isPresented: $showShareSheet) {
                if let url = shareURL {
                    ActivityView(activityItems: [url])
                }
            }
        }
        .tint(themeManager.currentAccent.primaryColor)
    }
    
    // Card 1: User Header
    private var userHeaderCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 50, weight: .semibold))
                .foregroundStyle(themeManager.currentAccent.primaryColor)
            
            
            VStack(alignment: .leading, spacing: 4) {
                Text(currentUser.name)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .allowsTightening(true)
                
                Text("\(currentUser.age) yrs old • \(currentUser.gender.displayName)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppColors.textSecondary)
            }
            
            Spacer()
            
            Button {
                showEditProfileSheet = true
            } label: {
                ZStack {
                    Circle()
                        .fill(themeManager.currentAccent.primaryColor.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "pencil")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(themeManager.currentAccent.primaryColor)
                }
            }
        }
        .padding(16)
        .background(themeManager.currentAccent.inputBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
    
    // Card 2: Appearance & Theme
    private var appearanceThemeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Appearance & Theme", systemImage: "paintpalette.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)
            
            Divider()
            
            // Accent Color Palette
            VStack(alignment: .leading, spacing: 10) {
                Text("Accent Color")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppColors.textSecondary)
                
                HStack(spacing: 12) {
                    ForEach(AppAccentColor.allCases) { accent in
                        Circle()
                            .fill(accent.primaryColor)
                            .frame(width: 36, height: 36)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: themeManager.currentAccent == accent ? 3 : 0)
                            )
                            .shadow(
                                color: accent.primaryColor.opacity(themeManager.currentAccent == accent ? 0.45 : 0),
                                radius: 5,
                                y: 2
                            )
                            .onTapGesture {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                    themeManager.currentAccent = accent
                                }
                            }
                    }
                }
            }
            
            Divider()
            
            // System / Light / Dark
            HStack {
                Text("Display Mode")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppColors.textPrimary)
                
                Spacer()
                
                Picker("", selection: $themeManager.currentTheme) {
                    ForEach(AppThemeMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
        }
        .padding(16)
        .background(themeManager.currentAccent.inputBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    // Card 3: Data & Preferences
    private var dataPreferencesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Data & Preferences", systemImage: "slider.horizontal.3")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)
            
            Divider()
            
            // Choose Currency
            HStack {
                HStack(spacing: 10) {
                    Image(systemName: "banknote.fill")
                        .foregroundStyle(themeManager.currentAccent.primaryColor)
                    Text("Currency Format")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppColors.textPrimary)
                }
                
                Spacer()
                
                Picker("", selection: $themeManager.currentCurrency) {
                    ForEach(CurrencyType.allCases) { currency in
                        Text(currency.rawValue).tag(currency)
                    }
                }
                .pickerStyle(.menu)
                .tint(themeManager.currentAccent.primaryColor)
            }
            
            Divider()
            
            // Clear All Transactions
            Button {
                showClearDataAlert = true
            } label: {
                HStack {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                            .foregroundStyle(Color.orange)
                        Text("Clear All Transactions")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.orange)
                    }
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(themeManager.currentAccent.inputBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    // Card 4: Danger Zone
    private var dangerZoneCard: some View {
        Button {
            showLogoutConfirmation = true
        } label: {
            HStack {
                Spacer()
                Image(systemName: "rectangle.portrait.and.arrow.right.fill")
                    .font(.system(size: 16, weight: .semibold))
                Text("Log Out & Wipe Data")
                    .font(.system(size: 15, weight: .bold))
                Spacer()
            }
            .foregroundStyle(AppColors.redBright)
            .padding(.vertical, 14)
            .background(AppColors.redBright.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

#Preview {
    ProfileScreen(
        transactionsViewModel: TransactionsViewModel(),
        onLogout: {print("1")}
    )
    .environmentObject(UserManager())
}
