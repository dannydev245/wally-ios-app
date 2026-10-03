//
//  MainTabScreen.swift
//  RandumApp
//
//  Created by dannyduy on 2/10/26.
//

import SwiftUI

struct MainTabScreens: View {
    var body: some View {
        TabView {
            HomeScreen()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            TransactionsScreen()
                .tabItem {
                    Label("Transactions", systemImage: "list.bullet.rectangle.portrait.fill")
                }
            
            AnalyzeScreen()
                .tabItem {
                    Label("Analyze", systemImage: "chart.pie.fill")
                }
            
            ProfileScreen()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
        .tint(AppColors.primary)
    }
}

#Preview {
    MainTabScreens()
}
