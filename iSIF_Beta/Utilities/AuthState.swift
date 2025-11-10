import SwiftUI
import FirebaseAuth

@MainActor
final class AuthState: ObservableObject {
    // Used by views
    @Published var isUserLoggedIn: Bool = false
    @Published var uid: String? = nil
    @Published var displayName: String? = nil
    @Published var photoURL: URL? = nil

    private var authHandle: AuthStateDidChangeListenerHandle?

    init() {
        apply(Auth.auth().currentUser)
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            Task { @MainActor in self.apply(user) }
        }
    }

    private func apply(_ user: User?) {
        if let u = user {
            isUserLoggedIn = true
            uid = u.uid
            displayName = u.displayName
            photoURL = u.photoURL
        } else {
            isUserLoggedIn = false
            uid = nil
            displayName = nil
            photoURL = nil
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            apply(nil)
        } catch {
            print("Sign-out failed: \(error.localizedDescription)")
        }
    }

    deinit {
        if let h = authHandle { Auth.auth().removeStateDidChangeListener(h) }
    }
}
