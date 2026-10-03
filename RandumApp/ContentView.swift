import SwiftUI

struct ContentView: View {
    @State private var currentUser: User? = nil
    //    nil | User(id: 1, email: "abc@gmail.com")
    
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
        if let savedData = UserDefaults.standard.data(forKey: "currentUser"),
           let decodedUser = try? JSONDecoder().decode(User.self, from: savedData) {
            self.currentUser = decodedUser
        }
    }
}

#Preview {
    ContentView()
}
