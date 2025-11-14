import SwiftUI
import FirebaseCore
import FirebaseFirestore

@main
struct iSIF_BetaApp: App {

    // MARK: - Global State Objects
    @StateObject private var authState = AuthState()
    @StateObject private var appState = AppState()
    @StateObject private var router = TabRouter()

    // MARK: - Initialize Firebase
    init() {
        FirebaseApp.configure()
        FirebaseConfiguration.shared.setLoggerLevel(.debug)
        Firestore.enableLogging(true)

        if let app = FirebaseApp.app() {
            print("✅ Firebase configured successfully:")
            print("   Name: \(app.name)")
            print("   Project ID: \(app.options.projectID ?? "nil")")
            print("   App ID: \(app.options.googleAppID)")
        } else {
            print("❌ Firebase failed to initialize. Check GoogleService-Info.plist.")
        }
    }

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

// MARK: - RootView
struct RootView: View {
    @EnvironmentObject var authState: AuthState
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var router: TabRouter

    var body: some View {
        Group {
            if authState.isUserLoggedIn {
                NavigationHostView()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                WelcomeView()
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.35), value: authState.isUserLoggedIn)
    }
}
