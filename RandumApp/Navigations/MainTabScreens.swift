//
//  MainTabScreen.swift
//  RandumApp
//
//  Created by dannyduy on 2/10/26.
//

import SwiftUI

struct MainTabScreens: View {
    var onLogout: () -> Void
    
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var userManager: UserManager
    @StateObject private var transactionsViewModel = TransactionsViewModel()
    
    @State private var selectedTab: MainAppTab = .home
    @State private var activeCreationMode: TransactionCreationMode? = nil
    @State private var smartConfirmResult: TransactionItem? = nil
    
    private var shouldShowFAB: Bool {
        selectedTab == .home || selectedTab == .transactions
    }
    
    var body: some View {
        Group{
            if userManager.currentUser != nil {
                mainContent
            } else {
                ProgressView()
            }
        }
    }
    
    private var mainContent: some View {
        ZStack(alignment: .bottomTrailing){
            tabViewContent
            fabOverlay
        }
        // 1. Creation Sheet (Manual Input & Voice Input)
        .sheet(item: creationSheetBinding) { mode in
            creationSheetView(for: mode)
        }
        // 2. FullScreen Cover Scan Receipt
        .fullScreenCover(isPresented: scanCoverBinding) {
            ReceiptScannerSheet { result in
                activeCreationMode = nil
                presentSmartConfirm(with: result)
            }
        }
        // 3. Sheet Smart Confirm
        .sheet(item: $smartConfirmResult) { result in
            SmartConfirmSheet(parsedResult: result) { confirmedItem in
                transactionsViewModel.addTransaction(confirmedItem)
            }
            .presentationDetents([.fraction(0.6)])
            .presentationDragIndicator(.hidden)
        }
    }
    
    private var tabViewContent: some View {
        TabView(selection: $selectedTab) {
            HomeScreen(
                transactionsViewModel: transactionsViewModel,
                onSeeAllTapped: { selectedTab = .transactions }
            )
            .id("home")
            .tabItem { Label("Home", systemImage: "house.fill") }
            .tag(MainAppTab.home)
            
            TransactionsScreen(
                viewModel: transactionsViewModel
            )
            .id("transactions")
            .tabItem { Label("Transactions", systemImage: "list.bullet.rectangle.portrait.fill") }
            .tag(MainAppTab.transactions)
            
            AnalyzeScreen(
                transactionsViewModel: transactionsViewModel
            )
            .id("analyze")
            .tabItem { Label("Analyze", systemImage: "chart.pie.fill") }
            .tag(MainAppTab.analyze)
            
            ProfileScreen(
                transactionsViewModel: transactionsViewModel,
                onLogout: {
                    transactionsViewModel.clearAllTransactions()
                    onLogout()
                }
            )
            .id("profile")
            .tabItem { Label("Profile", systemImage: "person.fill") }
            .tag(MainAppTab.profile)
        }
        .tint(themeManager.currentAccent.primaryColor)
        .onChange(of: themeManager.selectedAccentRaw) { _, _ in
            UIView.animate(withDuration: 0.25) {
                UITabBar.appearance().tintColor = UIColor(themeManager.currentAccent.primaryColor)
            }
        }
    }
    
    @ViewBuilder
    private var fabOverlay: some View {
        DraggableFAB { mode in
            activeCreationMode = mode
        }
        .transition(.scale.combined(with: .opacity))
        .opacity(shouldShowFAB ? 1 : 0)
        .allowsHitTesting(shouldShowFAB)
    }
    
    @ViewBuilder
    private func creationSheetView(for mode: TransactionCreationMode) -> some View {
        switch mode {
        case .manual:
            TransactionFormSheet(transactionToEdit: nil) { newTx in
                transactionsViewModel.addTransaction(newTx)
            }
            .presentationDetents([.fraction(0.68), .large])
            .presentationDragIndicator(.visible)
            
        case .voice:
            VoiceRecordingSheet { result in
                activeCreationMode = nil
                presentSmartConfirm(with: result)
            }
            .presentationDetents([.fraction(0.48)])
            .presentationDragIndicator(.hidden)
            
        case .scan:
            EmptyView()
        }
    }
    
    private var creationSheetBinding: Binding<TransactionCreationMode?> {
        Binding(
            get: { activeCreationMode == .scan ? nil : activeCreationMode },
            set: { activeCreationMode = $0 }
        )
    }
    
    private var scanCoverBinding: Binding<Bool> {
        Binding(
            get: { activeCreationMode == .scan },
            set: { if !$0 { activeCreationMode = nil } }
        )
    }
    
    private func presentSmartConfirm(with result: TransactionItem) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            self.smartConfirmResult = result
        }
    }
}

#Preview {
    MainTabScreens(onLogout: {print("1")})
        .environmentObject(UserManager.shared)
        .environmentObject(ThemeManager.shared)
}
