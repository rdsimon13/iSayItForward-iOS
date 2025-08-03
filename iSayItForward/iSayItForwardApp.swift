import SwiftUI
import FirebaseAuth
import FirebaseCore

@main
struct iSayItForwardApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authState = AuthState()

    var body: some Scene {
        WindowGroup {
            AppInitializationView()
                .environmentObject(authState)
        }
    }
}

// MARK: - Auth State Observable Object
class AuthState: ObservableObject {
    @Published var isUserLoggedIn = false
    @Published var currentUser: AppUser?
    @Published var isInitializing = true
    @Published var authError: String?
    
    private var authHandle: AuthStateDidChangeListenerHandle?

    init() {
        print("🔐 [AuthState] Initializing auth state listener...")
        
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] auth, user in
            DispatchQueue.main.async {
                self?.handleAuthStateChange(auth: auth, user: user)
            }
        }
        
        // Set initialization complete after a short delay to ensure Firebase is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isInitializing = false
            print("🔐 [AuthState] Auth state initialization complete")
        }
    }
    
    private func handleAuthStateChange(auth: Auth, user: User?) {
        let wasLoggedIn = isUserLoggedIn
        isUserLoggedIn = (user != nil)
        
        if let user = user {
            // User is signed in
            currentUser = AppUser(
                uid: user.uid,
                name: user.displayName ?? "User",
                email: user.email ?? ""
            )
            print("🔐 [AuthState] User signed in: \(user.email ?? user.uid)")
        } else {
            // User is signed out
            currentUser = nil
            print("🔐 [AuthState] User signed out")
        }
        
        // Clear any auth errors when state changes
        if wasLoggedIn != isUserLoggedIn {
            authError = nil
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            print("🔐 [AuthState] Manual sign out successful")
        } catch let signOutError as NSError {
            print("❌ [AuthState] Error signing out: \(signOutError.localizedDescription)")
            authError = signOutError.localizedDescription
        }
    }
    
    func signInDemo(email: String, name: String) {
        // For demo mode, we'll just set the user directly
        currentUser = AppUser(uid: "demo_\(UUID().uuidString)", name: name, email: email)
        isUserLoggedIn = true
        authError = nil
        print("🔐 [AuthState] Demo sign in: \(email)")
    }

    deinit {
        if let authHandle = authHandle {
            Auth.auth().removeStateDidChangeListener(authHandle)
            print("🔐 [AuthState] Auth listener removed")
        }
    }
}
