import SwiftUI

@main struct MyApp: App {
    @StateObject private var userManager = UserManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userManager)
                .preferredColorScheme(themeManager.currentTheme.colorScheme)
        }
    }
}
