import SwiftUI
import FirebaseAuth

@MainActor
final class AuthState: ObservableObject {
    @Published var isLoggedIn: Bool = false
    private var handle: AuthStateDidChangeListenerHandle?

    init() {
        // Listen for Firebase auth state changes
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            self.isLoggedIn = (user != nil)
            #if DEBUG
            print("DEBUG AuthState: isLoggedIn=\(self.isLoggedIn)")
            #endif
        }
    }

    deinit {
        if let handle { Auth.auth().removeStateDidChangeListener(handle) }
    }

    // Optional helpers
    func signOut() {
        do { try Auth.auth().signOut() } catch {
            print("Sign out error: \(error.localizedDescription)")
        }
    }
}
