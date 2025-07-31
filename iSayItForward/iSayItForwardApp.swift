import SwiftUI
import FirebaseAuth
import FirebaseCore

@main
struct iSayItForwardApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authService = AuthenticationService.shared
    @StateObject private var notificationService = NotificationService.shared

    var body: some Scene {
        WindowGroup {
            if UIDevice.current.userInterfaceIdiom == .pad {
                iPadMainView()
                    .environmentObject(authService)
                    .environmentObject(notificationService)
            } else {
                WelcomeView() // or ContentView() if you prefer
                    .environmentObject(authService)
                    .environmentObject(notificationService)
            }
        }
    }
}
