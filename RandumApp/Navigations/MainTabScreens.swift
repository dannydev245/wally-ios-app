//
//  MainTabScreen.swift
//  RandumApp
//
//  Created by dannyduy on 2/10/26.
//

import SwiftUI

struct MainTabScreens: View {
    var onLogout: () -> Void

    @State private var currentUser: User? = nil
    
    var body: some View {
        Group{
            if let user = currentUser {
                TabView {
                    HomeScreen(user: user)
                        .id("home")
                        .tabItem {
                            Label("Home", systemImage: "house.fill")
                        }
                    
                    TransactionsScreen()
                        .id("transactions")
                        .tabItem {
                            Label("Transactions", systemImage: "list.bullet.rectangle.portrait.fill")
                        }
                    
                    AnalyzeScreen()
                        .id("analyze")
                        .tabItem {
                            Label("Analyze", systemImage: "chart.pie.fill")
                        }
                    
                    ProfileScreen(onLogout: onLogout)
                        .id("profile")
                        .tabItem {
                            Label("Profile", systemImage: "person.fill")
                        }
                }
                .tint(AppColors.primary)
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
