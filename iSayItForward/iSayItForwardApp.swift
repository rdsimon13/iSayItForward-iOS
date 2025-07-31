import SwiftUI
import FirebaseAuth
import FirebaseCore

@main
struct iSayItForwardApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authManager = AuthenticationManager()

    var body: some Scene {
        WindowGroup {
            if UIDevice.current.userInterfaceIdiom == .pad {
                iPadMainView()
                    .environmentObject(authManager)
            } else {
                if authManager.isAuthenticated {
                    HomeView()
                        .environmentObject(authManager)
                } else {
                    WelcomeView()
                        .environmentObject(authManager)
                }
            }
        }
    }
}
