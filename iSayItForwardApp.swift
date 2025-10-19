import SwiftUI
import Firebase

@main
struct iSayItForwardApp: App {
    // Register the minimal app delegate
    @UIApplicationDelegateAdaptor(MinimalAppDelegate.self) var delegate
    
    // Track Firebase initialization state
    @State private var firebaseReady = false
    @State private var showSplash = true
    
    // State objects - created AFTER Firebase is ready
    @StateObject private var authState = AuthState()
    @StateObject private var matchDataState = MatchDataState()
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // Safe background color
                Color.white.ignoresSafeArea()
                
                if showSplash {
                    // Extremely minimal splash screen
                    VStack(spacing: 20) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                        Text("Starting...")
                            .font(.title2)
                        ProgressView()
                    }
                    .onAppear {
                        print("⏳ Splash screen appeared, initializing Firebase...")
                        // Wait 1 second before checking Firebase
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            if FirebaseApp.app() != nil {
                                print("✅ Firebase is ready, proceeding to main content")
                                self.firebaseReady = true
                                withAnimation { self.showSplash = false }
                            } else {
                                print("❌ Firebase not ready - something is wrong")
                            }
                        }
                    }
                } else if firebaseReady {
                    // Debug print to track progression
                    VStack {
                        // This is the key change - skip the coordinator and go directly to login
                        if authState.isLoggedIn {
                            MainAppView()
                                .environmentObject(authState)
                                .environmentObject(matchDataState)
                                .onAppear { print("🏠 Showing MainAppView") }
                        } else {
                            LoginView()
                                .environmentObject(authState)
                                .environmentObject(matchDataState)
                                .onAppear { print("🔑 Showing LoginView") }
                        }
                    }
                    .onAppear {
                        print("🚀 Firebase ready, auth state: \(authState.isLoggedIn ? "Logged in" : "Not logged in")")
                    }
                }
            }
        }
    }
}

// Simplified MainAppView that goes directly to GettingStartedView
struct MainAppView: View {
    @EnvironmentObject var authState: AuthState
    @EnvironmentObject var matchDataState: MatchDataState
    
    var body: some View {
        // Go straight to your GettingStartedView
        GettingStartedView()
            .onAppear {
                print("📱 GettingStartedView appeared")
            }
    }
}
