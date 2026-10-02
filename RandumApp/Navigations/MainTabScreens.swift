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
            // Tab 1: Ví dụ màn Home
            Text("Home Screen (Tab 1)")
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            // Tab 2: Ví dụ màn Profile / Settings
            Text("Profile Screen (Tab 2)")
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
