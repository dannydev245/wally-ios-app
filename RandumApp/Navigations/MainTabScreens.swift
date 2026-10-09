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
                    
                    //                    if selectedTab == .home || selectedTab == .transactions {
                    DraggableFAB {
                        showCreateSheet = true
                    }
                    .transition(.scale.combined(with: .opacity))
                    .opacity(shouldShowFAB ? 1 : 0)
                    .allowsHitTesting(shouldShowFAB)
                    //                    }
                }
                .sheet(isPresented: $showCreateSheet) {
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
