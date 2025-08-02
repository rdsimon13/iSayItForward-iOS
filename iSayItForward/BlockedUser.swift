import Foundation
import FirebaseFirestore

/// Represents a blocked user relationship
struct BlockedUser: Identifiable, Codable {
    @DocumentID var id: String?
    
    let blockerId: String       // UID of the user doing the blocking
    let blockedUserId: String   // UID of the user being blocked
    let timestamp: Date         // When the block was created
    let reason: BlockReason?    // Optional reason for blocking
}

/// Reasons for blocking a user
enum BlockReason: String, CaseIterable, Codable {
    case harassment = "harassment"
    case inappropriateContent = "inappropriate_content"
    case spam = "spam"
    case personalChoice = "personal_choice"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .harassment:
            return "Harassment"
        case .inappropriateContent:
            return "Inappropriate Content"
        case .spam:
            return "Spam"
        case .personalChoice:
            return "Personal Choice"
        case .other:
            return "Other"
        }
    }
}

/// Represents a user's blocking status and relationships
struct UserBlockingInfo {
    let userId: String
    let blockedUsers: Set<String>       // Users this user has blocked
    let blockedByUsers: Set<String>     // Users who have blocked this user
    
    /// Check if this user has blocked another user
    func hasBlocked(_ userId: String) -> Bool {
        return blockedUsers.contains(userId)
    }
    
    /// Check if this user is blocked by another user
    func isBlockedBy(_ userId: String) -> Bool {
        return blockedByUsers.contains(userId)
    }
    
    /// Check if there's any blocking relationship between two users
    func hasBlockingRelationship(with userId: String) -> Bool {
        return hasBlocked(userId) || isBlockedBy(userId)
    }
}