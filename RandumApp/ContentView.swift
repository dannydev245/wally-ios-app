import SwiftUI

struct ContentView: View {
    @State private var currentUser: User? = nil
    
    var body: some View {
        Group {
            if currentUser == nil {
                AuthStackScreens { user in
                    self.currentUser = user
                }
            } else {
                MainTabScreens()
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
}

#Preview {
    ContentView()
}
