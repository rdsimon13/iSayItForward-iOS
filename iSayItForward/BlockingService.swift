import Foundation
import FirebaseFirestore
import FirebaseAuth

/// Service for handling user blocking functionality
@MainActor
class BlockingService: ObservableObject {
    private let db = Firestore.firestore()
    @Published var blockedUsers: Set<String> = []
    @Published var isLoading = false
    
    // MARK: - User Blocking
    
    /// Block a user
    func blockUser(_ userId: String, reason: BlockReason? = nil) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw BlockingError.userNotAuthenticated
        }
        
        // Prevent users from blocking themselves
        if currentUserId == userId {
            throw BlockingError.cannotBlockSelf
        }
        
        // Check if already blocked
        if blockedUsers.contains(userId) {
            throw BlockingError.alreadyBlocked
        }
        
        let blockRecord = BlockedUser(
            blockerId: currentUserId,
            blockedUserId: userId,
            timestamp: Date(),
            reason: reason
        )
        
        try await db.collection("blocked_users").addDocument(from: blockRecord)
        
        // Update local state
        blockedUsers.insert(userId)
    }
    
    /// Unblock a user
    func unblockUser(_ userId: String) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw BlockingError.userNotAuthenticated
        }
        
        // Find the blocking record
        let snapshot = try await db.collection("blocked_users")
            .whereField("blockerId", isEqualTo: currentUserId)
            .whereField("blockedUserId", isEqualTo: userId)
            .getDocuments()
        
        guard let document = snapshot.documents.first else {
            throw BlockingError.blockNotFound
        }
        
        try await document.reference.delete()
        
        // Update local state
        blockedUsers.remove(userId)
    }
    
    /// Check if a user is blocked
    func isUserBlocked(_ userId: String) -> Bool {
        return blockedUsers.contains(userId)
    }
    
    /// Load blocked users for the current user
    func loadBlockedUsers() async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw BlockingError.userNotAuthenticated
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let snapshot = try await db.collection("blocked_users")
            .whereField("blockerId", isEqualTo: currentUserId)
            .getDocuments()
        
        let blockedUserIds = snapshot.documents.compactMap { doc in
            try? doc.data(as: BlockedUser.self)?.blockedUserId
        }
        
        blockedUsers = Set(blockedUserIds)
    }
    
    /// Get detailed blocking information for the current user
    func getUserBlockingInfo() async throws -> UserBlockingInfo {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw BlockingError.userNotAuthenticated
        }
        
        // Get users this user has blocked
        let blockedSnapshot = try await db.collection("blocked_users")
            .whereField("blockerId", isEqualTo: currentUserId)
            .getDocuments()
        
        let blockedUsers = Set(blockedSnapshot.documents.compactMap { doc in
            try? doc.data(as: BlockedUser.self)?.blockedUserId
        })
        
        // Get users who have blocked this user
        let blockedBySnapshot = try await db.collection("blocked_users")
            .whereField("blockedUserId", isEqualTo: currentUserId)
            .getDocuments()
        
        let blockedByUsers = Set(blockedBySnapshot.documents.compactMap { doc in
            try? doc.data(as: BlockedUser.self)?.blockerId
        })
        
        return UserBlockingInfo(
            userId: currentUserId,
            blockedUsers: blockedUsers,
            blockedByUsers: blockedByUsers
        )
    }
    
    /// Get all blocked users with details (for settings/management)
    func getBlockedUsersWithDetails() async throws -> [BlockedUserDetail] {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw BlockingError.userNotAuthenticated
        }
        
        let snapshot = try await db.collection("blocked_users")
            .whereField("blockerId", isEqualTo: currentUserId)
            .order(by: "timestamp", descending: true)
            .getDocuments()
        
        var blockedDetails: [BlockedUserDetail] = []
        
        for document in snapshot.documents {
            guard let blockRecord = try? document.data(as: BlockedUser.self) else { continue }
            
            // Get user details
            let userDoc = try await db.collection("users").document(blockRecord.blockedUserId).getDocument()
            let userName = userDoc.data()?["name"] as? String ?? "Unknown User"
            let userEmail = userDoc.data()?["email"] as? String ?? ""
            
            let detail = BlockedUserDetail(
                blockRecord: blockRecord,
                userName: userName,
                userEmail: userEmail
            )
            
            blockedDetails.append(detail)
        }
        
        return blockedDetails
    }
    
    // MARK: - Content Filtering
    
    /// Filter a list of SIF items to exclude content from blocked users
    func filterContentFromBlockedUsers(_ sifs: [SIFItem]) -> [SIFItem] {
        return sifs.filter { sif in
            !isUserBlocked(sif.authorUid)
        }
    }
    
    /// Check if interaction should be prevented due to blocking
    func shouldPreventInteraction(with userId: String) async throws -> Bool {
        let blockingInfo = try await getUserBlockingInfo()
        return blockingInfo.hasBlockingRelationship(with: userId)
    }
}

// MARK: - Supporting Types

struct BlockedUserDetail {
    let blockRecord: BlockedUser
    let userName: String
    let userEmail: String
}

enum BlockingError: LocalizedError {
    case userNotAuthenticated
    case cannotBlockSelf
    case alreadyBlocked
    case blockNotFound
    case userNotFound
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "You must be signed in to perform this action."
        case .cannotBlockSelf:
            return "You cannot block yourself."
        case .alreadyBlocked:
            return "This user is already blocked."
        case .blockNotFound:
            return "Block record not found."
        case .userNotFound:
            return "User not found."
        }
    }
}