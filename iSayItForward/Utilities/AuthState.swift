import SwiftUI
import FirebaseAuth

/// Global authentication state tracker for the app.
/// Observes the user’s login status and provides simple access
/// for views to reactively update UI based on authentication.
@MainActor
final class AuthState: ObservableObject {

    // MARK: - Published Properties
    /// Indicates whether a user is currently logged in.
    @Published var isUserLoggedIn: Bool = false

    /// Firebase Auth listener handle (for automatic state updates)
    private var authHandle: AuthStateDidChangeListenerHandle?

    // MARK: - Optional Shared App State
    /// App-wide shared state (e.g., selected tab or screen)
    class AppState: ObservableObject {
        @Published var selectedTab: String = "home"
    }

    // MARK: - Initialization
    init() {
        // Immediately reflect current user status
        isUserLoggedIn = (Auth.auth().currentUser != nil)

        // Attach listener for ongoing auth changes
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let user = user {
                    self.isUserLoggedIn = true
                    print("Logged in as user: \(user.uid)")
                } else {
                    self.isUserLoggedIn = false
                    print("No user logged in.")
                }
            }
        }
    }

    // MARK: - Sign Out
    /// Signs the user out and resets login state.
    func signOut() {
        do {
            try Auth.auth().signOut()
            isUserLoggedIn = false
            print("User signed out successfully.")
        } catch {
            print("Sign-out failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Cleanup
    /// Removes the Firebase listener when no longer needed.
    deinit {
        if let handle = authHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}
