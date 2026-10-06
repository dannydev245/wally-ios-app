//
//  MainTabScreen.swift
//  RandumApp
//
//  Created by dannyduy on 2/10/26.
//

import SwiftUI

struct MainTabScreens: View {
    var onLogout: () -> Void
    
    @State private var selectedTab: MainAppTab = .home
    @State private var currentUser: User? = nil
    @State private var showCreateSheet: Bool = false
    
    @StateObject private var transactionsViewModel = TransactionsViewModel()
    
    var body: some View {
        Group{
            if let user = currentUser {
                ZStack(alignment: .bottomTrailing){
                    
                    
                    TabView(selection: $selectedTab) {
                        HomeScreen(
                            user: user,
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
                        
                        ProfileScreen(onLogout: onLogout)
                            .id("profile")
                            .tabItem {
                                Label("Profile", systemImage: "person.fill")
                            }
                            .tag(MainAppTab.profile)
                    }
                    .tint(AppColors.primary)
                    
                    if selectedTab == .home || selectedTab == .transactions {
                        DraggableFAB {
                            showCreateSheet = true
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
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
        .onAppear {
            if let savedUser = UserDefaults.standard.savedUser {
                self.currentUser = savedUser
            } else {
                onLogout()
            }
        }
    }
}

#Preview {
    MainTabScreens(onLogout: {print("1")})
}
