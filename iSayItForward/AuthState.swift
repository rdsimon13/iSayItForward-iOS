import Foundation
import Firebase
import FirebaseAuth

class AuthState: ObservableObject {
    @Published var user: FirebaseAuth.User?
    @Published var isLoggedIn = false
    private var authStateDidChangeListenerHandle: AuthStateDidChangeListenerHandle?
    
    init() {
        print("📊 AuthState initializing...")
        
        // Only set up listener if Firebase is already initialized
        guard FirebaseApp.app() != nil else {
            print("⚠️ AuthState init: Firebase not ready")
            return
        }
        
        print("🔑 Setting up auth listener")
        authStateDidChangeListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.user = user
                self.isLoggedIn = user != nil
                print("👤 Auth state updated: \(user != nil ? "User logged in" : "No user")")
            }
        }
    }
    
    func signIn(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        guard FirebaseApp.app() != nil else {
            completion(false, "Firebase not initialized")
            return
        }
        
        print("🔐 Attempting sign in with email: \(email)")
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Sign in error: \(error.localizedDescription)")
                completion(false, error.localizedDescription)
                return
            }
            
            print("✅ Sign in successful")
            DispatchQueue.main.async {
                self.isLoggedIn = true
                completion(true, nil)
            }
        }
    }
    
    // For development only - simulate a logged in user
    func simulateLogin() {
        print("🧪 Simulating login for development")
        DispatchQueue.main.async {
            self.isLoggedIn = true
        }
    }
    
    deinit {
        if let handle = authStateDidChangeListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}
