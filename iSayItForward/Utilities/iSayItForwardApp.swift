import SwiftUI
import FirebaseCore
import FirebaseAuth

@main
struct iSayItForwardApp: App {
    // MARK: - App Delegate (Google Sign-In + Notifications)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    // MARK: - Global State Objects
    @StateObject private var authState = AuthState() // ✅ Handles login tracking
    @StateObject private var appState = AppState()
    @StateObject private var router = TabRouter()


    // MARK: - Main Scene
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authState)
                .environmentObject(appState)
                .environmentObject(router)
                .applyGlobalFont()
        }
    }
}

// MARK: - RootView Wrapper
struct RootView: View {
    @EnvironmentObject var authState: AuthState
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var router: TabRouter

    var body: some View {
        Group {
            if authState.isUserLoggedIn {
                NavigationHostView() // ✅ your Dashboard
                    .environmentObject(authState)
                    .environmentObject(appState)
                    .environmentObject(router)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                WelcomeView()
                    .environmentObject(authState)
                    .environmentObject(appState)
                    .environmentObject(router)
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.35), value: authState.isUserLoggedIn)
    }
}
