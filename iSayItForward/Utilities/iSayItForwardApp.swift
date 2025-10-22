import SwiftUI
import FirebaseCore
import FirebaseAuth

@main
struct iSayItForwardApp: App {
    // MARK: - App Delegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    // MARK: - Auth State
    @StateObject private var authState = AuthState()

    // MARK: - Init (Global Setup)
    init() {
        // ✅ Firebase config is already in AppDelegate — do not call again here.
        FontTheme.setupGlobalFontAppearance()
    }

    // MARK: - Scene Body
    var body: some Scene {
        WindowGroup {
            Group {
                if authState.isUserLoggedIn {
                    AppFlowCoordinator()
                        .environmentObject(authState)
                        .applyGlobalFont() // 👈 Global SwiftUI font modifier
                } else {
                    WelcomeView()
                        .environmentObject(authState)
                        .applyGlobalFont()
                }
            }
        }
    }
}
