import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var userManager: UserManager
    
    var body: some View {
        Group {
            if userManager.currentUser == nil {
                AuthStackScreens{ newUser in
                    userManager.login(user: newUser)
                }
            } else {
                MainTabScreens{
                    userManager.logout()
                }
            }
        }
        .tint(AppColors.primary)
    }
}

#Preview {
    ContentView()
        .environmentObject(UserManager())
}
