import SwiftUI
import FirebaseAuth
import FirebaseCore

@main
struct iSayItForwardApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authState = AuthState()

    var body: some Scene {
        WindowGroup {
            if UIDevice.current.userInterfaceIdiom == .pad {
                iPadMainView()
                    .environmentObject(authState)
                    .onAppear {
                        print("📱 iPad interface detected - loading iPadMainView")
                    }
            } else {
                WelcomeView() // or ContentView() if you prefer
                    .environmentObject(authState)
                    .onAppear {
                        print("📱 iPhone interface detected - loading WelcomeView")
                    }
            }
        }
        .onAppear {
            print("🚀 iSayItForward app launching...")
        }
    }
}

// MARK: - Auth State Observable Object
class AuthState: ObservableObject {
    @Published var isUserLoggedIn = false
    private var authHandle: AuthStateDidChangeListenerHandle?

    init() {
        print("🔐 AuthState initializing...")
        authHandle = Auth.auth().addStateDidChangeListener { auth, user in
            DispatchQueue.main.async {
                self.isUserLoggedIn = (user != nil)
                if let user = user {
                    print("✅ User authenticated: \(user.uid)")
                } else {
                    print("👤 No user authenticated")
                }
            }
        }
    }

    deinit {
        if let authHandle = authHandle {
            Auth.auth().removeStateDidChangeListener(authHandle)
            print("🔐 AuthState deinitialized")
        }
    }
}
