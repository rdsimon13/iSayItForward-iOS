import SwiftUI
import FirebaseCore
import FirebaseAuth

@main
struct iSayItForwardApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authState = AuthState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authState)
        }
    }
}

// MARK: - AuthState (Global Authentication Manager)
class AuthState: ObservableObject {
    @Published var isUserLoggedIn = false
    private var authHandle: AuthStateDidChangeListenerHandle?

    init() {
        authHandle = Auth.auth().addStateDidChangeListener { _, user in
            DispatchQueue.main.async {
                self.isUserLoggedIn = (user != nil)
            }
        }
    }

    deinit {
        if let handle = authHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            isUserLoggedIn = false
        } catch {
            print("❌ Sign-out failed: \(error.localizedDescription)")
        }
    }
}
