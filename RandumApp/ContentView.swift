import SwiftUI

struct ContentView: View {
    @State private var currentUser: User? = nil
//    nil | User(id: 1, email: "abc@gmail.com")
    
    var body: some View {
        Group {
            if currentUser == nil {
                AuthStackScreens()
            } else {
                MainTabScreens()
            }
        }
        .tint(AppColors.primary)
    }
}

#Preview {
    ContentView()
}
