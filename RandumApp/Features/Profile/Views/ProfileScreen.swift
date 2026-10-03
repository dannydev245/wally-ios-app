//
//  ProfileScreen.swift
//  RandumApp
//
//  Created by dannyduy on 3/10/26.
//

import SwiftUI

struct ProfileScreen: View {
    var onLogout: () -> Void
    var body: some View {
        VStack(spacing: 20) {
            Text("Profile Screen")
                .font(.headline)
            
            Button(role: .destructive, action: onLogout) {
                Label("Log out", systemImage: "rectangle.portrait.and.arrow.right")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .foregroundStyle(.red)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 24)
        }
    }
}

#Preview {
    ProfileScreen(onLogout: {print("1")})
}
