import SwiftUI
import FirebaseAuth
import FirebaseCore

@main
struct iSayItForwardApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authState = AuthState()
    @StateObject private var persistenceManager = PersistenceManager.shared

    var body: some Scene {
        WindowGroup {
            if UIDevice.current.userInterfaceIdiom == .pad {
                iPadMainView()
                    .environmentObject(authState)
                    .environment(\.managedObjectContext, persistenceManager.context)
            } else {
                WelcomeView() // or ContentView() if you prefer
                    .environmentObject(authState)
                    .environment(\.managedObjectContext, persistenceManager.context)
            }
        }
    }
}

// MARK: - Auth State Observable Object
class AuthState: ObservableObject {
    @Published var isUserLoggedIn = false
    private var authHandle: AuthStateDidChangeListenerHandle?

    init() {
        authHandle = Auth.auth().addStateDidChangeListener { auth, user in
            self.isUserLoggedIn = (user != nil)
        }
    }

    deinit {
        if let authHandle = authHandle {
            Auth.auth().removeStateDidChangeListener(authHandle)
        }
    }
}
