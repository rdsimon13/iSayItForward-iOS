import SwiftUI
import FirebaseAuth

final class AuthState: ObservableObject {
    @Published var isUserLoggedIn = false
    private var authHandle: AuthStateDidChangeListenerHandle?

    init() {
        // ✅ Immediately sync current user on startup
        self.isUserLoggedIn = (Auth.auth().currentUser != nil)

        // ✅ Set up Firebase listener for future auth changes
        authHandle = Auth.auth().addStateDidChangeListener { _, user in
            DispatchQueue.main.async {
                let loggedIn = (user != nil)
                if self.isUserLoggedIn != loggedIn {
                    self.isUserLoggedIn = loggedIn
                    print("🧭 Firebase user changed → \(loggedIn ? "LOGGED IN" : "LOGGED OUT")")
                }
            }
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            // Listener automatically sets isUserLoggedIn = false
            print("👋 User signed out")
        } catch {
            print("❌ Sign-out failed: \(error.localizedDescription)")
        }
    }

    deinit {
        if let handle = authHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}
