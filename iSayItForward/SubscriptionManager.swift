import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

// MARK: - Subscription Manager
@MainActor
class SubscriptionManager: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var error: String?
    
    private let db = Firestore.firestore()
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    init() {
        setupAuthStateListener()
    }
    
    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
    
    // MARK: - Auth State Management
    private func setupAuthStateListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task {
                if let user = user {
                    await self?.fetchUserData(uid: user.uid)
                } else {
                    await MainActor.run {
                        self?.currentUser = nil
                    }
                }
            }
        }
    }
    
    // MARK: - User Data Management
    func fetchUserData(uid: String) async {
        isLoading = true
        error = nil
        
        do {
            let document = try await db.collection("users").document(uid).getDocument()
            
            if document.exists, let data = document.data() {
                currentUser = User(from: data)
            } else {
                // User document doesn't exist, this shouldn't happen but handle gracefully
                error = "User data not found"
            }
        } catch {
            self.error = "Failed to fetch user data: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func createUser(_ user: User) async -> Bool {
        isLoading = true
        error = nil
        
        do {
            try await db.collection("users").document(user.uid).setData(user.toFirestoreData())
            currentUser = user
            isLoading = false
            return true
        } catch {
            self.error = "Failed to create user: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    func updateUser(_ user: User) async -> Bool {
        isLoading = true
        error = nil
        
        do {
            let updatedUser = User(
                uid: user.uid,
                name: user.name,
                email: user.email,
                tier: user.tier
            )
            
            try await db.collection("users").document(user.uid).updateData(updatedUser.toFirestoreData())
            currentUser = updatedUser
            isLoading = false
            return true
        } catch {
            self.error = "Failed to update user: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    // MARK: - Tier Management
    func upgradeTier(to newTier: UserTier) async -> Bool {
        guard let currentUser = currentUser else {
            error = "No user logged in"
            return false
        }
        
        // In a real app, you would integrate with payment processing here
        // For now, we'll simulate a successful upgrade
        
        isLoading = true
        error = nil
        
        do {
            let updatedUser = User(
                uid: currentUser.uid,
                name: currentUser.name,
                email: currentUser.email,
                tier: newTier
            )
            
            try await db.collection("users").document(currentUser.uid).updateData(updatedUser.toFirestoreData())
            self.currentUser = updatedUser
            isLoading = false
            return true
        } catch {
            self.error = "Failed to upgrade tier: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    func downgradeTier(to newTier: UserTier) async -> Bool {
        guard let currentUser = currentUser else {
            error = "No user logged in"
            return false
        }
        
        // Ensure we're actually downgrading
        guard newTier.rawValue < currentUser.tier.rawValue else {
            error = "Cannot downgrade to a higher tier"
            return false
        }
        
        isLoading = true
        error = nil
        
        do {
            let updatedUser = User(
                uid: currentUser.uid,
                name: currentUser.name,
                email: currentUser.email,
                tier: newTier
            )
            
            try await db.collection("users").document(currentUser.uid).updateData(updatedUser.toFirestoreData())
            self.currentUser = updatedUser
            isLoading = false
            return true
        } catch {
            self.error = "Failed to downgrade tier: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    // MARK: - Feature Gating Helpers
    func canAccessFeature(requiredTier: UserTier) -> Bool {
        guard let user = currentUser else { return false }
        return user.effectiveTier.canAccessFeature(requiredTier: requiredTier)
    }
    
    func canCreateSIF() -> Bool {
        guard let user = currentUser else { return false }
        // Here you would check against usage limits based on tier
        // For now, just check if they have access
        return true
    }
    
    func getRemainingDataAllowance() -> Int {
        guard let user = currentUser else { return 0 }
        let limit = user.effectiveTier.dataLimitMB
        return limit == -1 ? Int.max : limit
        // In a real app, you'd subtract used data from the limit
    }
    
    func shouldShowAds() -> Bool {
        guard let user = currentUser else { return true }
        return user.effectiveTier.showsAds
    }
}