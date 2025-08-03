import SwiftUI
import FirebaseAuth
import FirebaseCore

@main
struct iSayItForwardApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authState = AuthState()

    var body: some Scene {
        WindowGroup {
            Group {
                if UIDevice.current.userInterfaceIdiom == .pad {
                    iPadMainView()
                        .environmentObject(authState)
                        .onAppear {
                            print("📱 App: iPad interface loaded")
                        }
                } else {
                    WelcomeView()
                        .environmentObject(authState)
                        .onAppear {
                            print("📱 App: iPhone interface loaded")
                        }
                }
            }
            .onAppear {
                print("🚀 App: Main app started")
            }
        }
    }
}

// MARK: - Auth State Observable Object
class AuthState: ObservableObject {
    @Published var isUserLoggedIn = false
    private var authHandle: AuthStateDidChangeListenerHandle?

    init() {
        print("🔐 AuthState: Initializing authentication listener")
        authHandle = Auth.auth().addStateDidChangeListener { auth, user in
            DispatchQueue.main.async {
                self.isUserLoggedIn = (user != nil)
                print("🔐 AuthState: User logged in status: \(self.isUserLoggedIn)")
            }
        }
    }

    deinit {
        if let authHandle = authHandle {
            Auth.auth().removeStateDidChangeListener(authHandle)
        }
    }
}
