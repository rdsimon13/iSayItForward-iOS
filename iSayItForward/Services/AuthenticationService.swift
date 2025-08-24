import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

// MARK: - Authentication Service
class AuthenticationService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var currentAppUser: AppUser?
    
    private var authHandle: AuthStateDidChangeListenerHandle?
    private let db = Firestore.firestore()
    
    static let shared = AuthenticationService()
    
    private init() {
        setupAuthStateListener()
    }
    
    deinit {
        if let authHandle = authHandle {
            Auth.auth().removeStateDidChangeListener(authHandle)
        }
    }
    
    // MARK: - Authentication State Monitoring
    private func setupAuthStateListener() {
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] auth, user in
            DispatchQueue.main.async {
                self?.currentUser = user
                self?.isAuthenticated = user != nil
                
                if let user = user {
                    self?.fetchUserData(uid: user.uid)
                } else {
                    self?.currentAppUser = nil
                }
            }
        }
    }
    
    // MARK: - User Data Management
    private func fetchUserData(uid: String) {
        db.collection("users").document(uid).getDocument { [weak self] snapshot, error in
            if let document = snapshot, document.exists {
                let data = document.data() ?? [:]
                let appUser = AppUser(
                    uid: uid,
                    name: data["name"] as? String ?? "",
                    email: data["email"] as? String ?? ""
                )
                DispatchQueue.main.async {
                    self?.currentAppUser = appUser
                }
            }
        }
    }
    
    // MARK: - Demo Authentication Methods
    func signInDemo(email: String, name: String = "Demo User") {
        let demoUser = AppUser(uid: "demo_\(UUID().uuidString)", name: name, email: email)
        DispatchQueue.main.async {
            self.currentAppUser = demoUser
            self.isAuthenticated = true
        }
    }
    
    func signUpDemo(name: String, email: String) {
        let demoUser = AppUser(uid: "demo_\(UUID().uuidString)", name: name, email: email)
        DispatchQueue.main.async {
            self.currentAppUser = demoUser
            self.isAuthenticated = true
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                self.currentUser = nil
                self.currentAppUser = nil
                self.isAuthenticated = false
            }
        } catch {
            print("Error signing out: \(error)")
        }
    }
    
    // MARK: - Real Firebase Authentication Methods (for future use)
    func signIn(email: String, password: String) async throws {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        await MainActor.run {
            self.currentUser = result.user
        }
    }
    
    func signUp(email: String, password: String, name: String) async throws {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        
        // Save user data to Firestore
        let userData: [String: Any] = [
            "name": name,
            "email": email,
            "createdAt": Timestamp()
        ]
        
        try await db.collection("users").document(result.user.uid).setData(userData)
        
        await MainActor.run {
            self.currentUser = result.user
        }
    }
}