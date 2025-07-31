import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

@MainActor
class UserDataManager: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private var userListener: ListenerRegistration?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Listen for auth state changes
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                if let user = user {
                    await self?.fetchUserData(uid: user.uid)
                } else {
                    self?.currentUser = nil
                    self?.removeUserListener()
                }
            }
        }
    }
    
    deinit {
        removeUserListener()
    }
    
    // MARK: - User Data Operations
    
    func fetchUserData(uid: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Set up real-time listener
            userListener = db.collection("users").document(uid).addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor in
                    if let error = error {
                        self?.errorMessage = "Failed to fetch user data: \(error.localizedDescription)"
                        self?.isLoading = false
                        return
                    }
                    
                    guard let document = snapshot, document.exists,
                          let data = document.data() else {
                        // User document doesn't exist, create it
                        await self?.createUserDocument(uid: uid)
                        return
                    }
                    
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: data)
                        let user = try JSONDecoder().decode(User.self, from: jsonData)
                        self?.currentUser = user
                        self?.isLoading = false
                    } catch {
                        self?.errorMessage = "Failed to decode user data: \(error.localizedDescription)"
                        self?.isLoading = false
                    }
                }
            }
        } catch {
            errorMessage = "Failed to set up user listener: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    func createUserDocument(uid: String) async {
        guard let firebaseUser = Auth.auth().currentUser else { return }
        
        let user = User(
            uid: uid,
            name: firebaseUser.displayName ?? "User",
            email: firebaseUser.email ?? ""
        )
        
        await updateUser(user)
    }
    
    func updateUser(_ user: User) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(user)
            let dictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
            
            try await db.collection("users").document(user.uid).setData(dictionary, merge: true)
            
            // Update local state
            currentUser = user
            isLoading = false
        } catch {
            errorMessage = "Failed to update user: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    func updateUserField<T: Codable>(_ keyPath: WritableKeyPath<User, T>, value: T) async {
        guard var user = currentUser else { return }
        user[keyPath: keyPath] = value
        user.updatedAt = Date()
        await updateUser(user)
    }
    
    func updatePrivacySettings(_ settings: PrivacySettings) async {
        guard var user = currentUser else { return }
        user.privacySettings = settings
        user.updatedAt = Date()
        await updateUser(user)
    }
    
    func updateNotificationSettings(_ settings: NotificationSettings) async {
        guard var user = currentUser else { return }
        user.notificationSettings = settings
        user.updatedAt = Date()
        await updateUser(user)
    }
    
    func incrementSIFStatistic(_ type: SIFStatisticType) async {
        guard var user = currentUser else { return }
        
        switch type {
        case .created:
            user.sifsCreated += 1
        case .sent:
            user.sifsSent += 1
        case .received:
            user.sifsReceived += 1
        }
        
        user.updatedAt = Date()
        await updateUser(user)
    }
    
    func deleteUserAccount() async throws {
        guard let user = Auth.auth().currentUser else {
            throw UserDataError.notAuthenticated
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Delete user document from Firestore
            try await db.collection("users").document(user.uid).delete()
            
            // Delete Firebase Auth account
            try await user.delete()
            
            // Clear local state
            currentUser = nil
            removeUserListener()
            isLoading = false
        } catch {
            errorMessage = "Failed to delete account: \(error.localizedDescription)"
            isLoading = false
            throw error
        }
    }
    
    // MARK: - Helper Methods
    
    private func removeUserListener() {
        userListener?.remove()
        userListener = nil
    }
    
    func retryLastOperation() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        await fetchUserData(uid: uid)
    }
}

// MARK: - Supporting Types

enum SIFStatisticType {
    case created
    case sent
    case received
}

enum UserDataError: LocalizedError {
    case notAuthenticated
    case userNotFound
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User is not authenticated"
        case .userNotFound:
            return "User data not found"
        case .invalidData:
            return "Invalid user data"
        }
    }
}