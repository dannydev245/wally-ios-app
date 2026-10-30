//
//  MainTabScreen.swift
//  RandumApp
//
//  Created by dannyduy on 2/10/26.
//

import SwiftUI

struct MainTabScreens: View {
    var onLogout: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    @State private var selectedTab: MainAppTab = .home
    @State private var showCreateSheet: Bool = false
    
    @StateObject private var transactionsViewModel = TransactionsViewModel()
    @EnvironmentObject private var userManager: UserManager
    
    @State private var activeCreationMode: TransactionCreationMode? = nil
    @State private var smartConfirmResult: ParsedTransactionResult? = nil
    
    var body: some View {
        Group{
            if userManager.currentUser != nil {
                ZStack(alignment: .bottomTrailing){
                    TabView(selection: $selectedTab) {
                        HomeScreen(
                            transactionsViewModel: transactionsViewModel,
                            onSeeAllTapped: {
                                selectedTab = .transactions
                            }
                        )
                        .id("home")
                        .tabItem {
                            Label("Home", systemImage: "house.fill")
                        }
                        .tag(MainAppTab.home)
                        
                        TransactionsScreen(
                            viewModel: transactionsViewModel
                        )
                        .id("transactions")
                        .tabItem {
                            Label("Transactions", systemImage: "list.bullet.rectangle.portrait.fill")
                        }
                        .tag(MainAppTab.transactions)
                        
                        AnalyzeScreen(
                            transactionsViewModel: transactionsViewModel
                        )
                        .id("analyze")
                        .tabItem {
                            Label("Analyze", systemImage: "chart.pie.fill")
                        }
                        .tag(MainAppTab.analyze)
                        
                        ProfileScreen(
                            transactionsViewModel: transactionsViewModel,
                            onLogout: {
                                transactionsViewModel.clearAllTransactions()
                                onLogout()
                            }
                        )
                        .id("profile")
                        .tabItem {
                            Label("Profile", systemImage: "person.fill")
                        }
                        .tag(MainAppTab.profile)
                    }
                    .tint(themeManager.currentAccent.primaryColor)
                    .onChange(of: themeManager.selectedAccentRaw) { _, _ in
                        UIView.animate(withDuration: 0.25) {
                            UITabBar.appearance().tintColor = UIColor(themeManager.currentAccent.primaryColor)
                        }
                    }
                    
                    
                    let shouldShowFAB = selectedTab == .home || selectedTab == .transactions
                    
                    DraggableFAB { mode in
                        activeCreationMode = mode
                    }
                    .transition(.scale.combined(with: .opacity))
                    .opacity(shouldShowFAB ? 1 : 0)
                    .allowsHitTesting(shouldShowFAB)
                }
                // 2. Sheet Manual Input
                .sheet(isPresented: Binding(
                    get: { activeCreationMode == .manual },
                    set: { if !$0 { activeCreationMode = nil } }
                )) {
                    TransactionFormSheet(transactionToEdit: nil) { title, amount, date, type, category in
                        transactionsViewModel.addTransaction(
                            title: title,
                            amount: amount,
                            date: date,
                            type: type,
                            category: category
                        )
                    }
                    .presentationDetents([.fraction(0.68), .large])
                    .presentationDragIndicator(.visible)
                }
                // 2. Sheet Voice Input
                .sheet(isPresented: Binding(
                    get: { activeCreationMode == .voice },
                    set: { if !$0 { activeCreationMode = nil } }
                )) {
                    VoiceRecordingSheet { result in
                        activeCreationMode = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            smartConfirmResult = result
                        }
                    }
                    .presentationDetents([.fraction(0.48)])
                    .presentationDragIndicator(.hidden)
                }
                // 3. FullScreen Cover Scan Receipt
                .fullScreenCover(isPresented: Binding(
                    get: { activeCreationMode == .scan },
                    set: { if !$0 { activeCreationMode = nil } }
                )) {
                    ReceiptScannerSheet { result in
                        activeCreationMode = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            smartConfirmResult = result
                        }
                    }
                }
                // Sheet Smart Confirm
                .sheet(item: $smartConfirmResult) { result in
                    SmartConfirmSheet(parsedResult: result) { confirmedResult in
                        transactionsViewModel.addTransaction(
                            title: confirmedResult.title,
                            amount: confirmedResult.amount,
                            date: confirmedResult.date,
                            type: confirmedResult.type,
                            category: confirmedResult.category
                        )
                    }
                    .presentationDetents([.fraction(0.6)])
                    .presentationDragIndicator(.hidden)
                }
            } else {
                ProgressView()
            }
        }
    }
}

#Preview {
    MainTabScreens(onLogout: {print("1")})
        .environmentObject(UserManager())
}
