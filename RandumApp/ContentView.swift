import SwiftUI

struct ContentView: View {
    @State private var currentUser: User? = nil
    
    var body: some View {
        Group {
            if currentUser == nil {
                AuthStackScreens(onUserAuthenticated: login)
            } else {
                MainTabScreens(onLogout: logout)
            }
        }
        .tint(AppColors.primary)
        .onAppear{
            loadCurrentUser()
        }
    }
    
    private func loadCurrentUser(){
        self.currentUser = UserDefaults.standard.savedUser
    }
    
    private func login(_ newUser: User) {
        withAnimation {
            self.currentUser = newUser
        }
    }
    
    private func logout() {
        UserDefaults.standard.savedUser = nil
        withAnimation {
            self.currentUser = nil
        }
    }
}

#Preview {
    ContentView()
}
