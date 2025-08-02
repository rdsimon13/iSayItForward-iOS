import Foundation

/// Utility class for content filtering and safety checks
class ContentFilterUtility {
    
    /// Filter SIF items based on content safety rules
    static func filterContent(_ sifs: [SIFItem], for currentUserId: String, blockedUsers: Set<String>) -> [SIFItem] {
        return sifs.filter { sif in
            // Filter out removed content
            if sif.isRemoved {
                return false
            }
            
            // Filter out content from blocked users
            if blockedUsers.contains(sif.authorUid) {
                return false
            }
            
            // Allow user's own content even if they're in blockedUsers set
            if sif.authorUid == currentUserId {
                return true
            }
            
            return true
        }
    }
    
    /// Check if content should be shown to a specific user
    static func shouldShowContent(_ sif: SIFItem, to userId: String, blockingInfo: UserBlockingInfo) -> Bool {
        // Don't show removed content
        if sif.isRemoved {
            return false
        }
        
        // Don't show content from blocked users
        if blockingInfo.hasBlocked(sif.authorUid) {
            return false
        }
        
        // Don't show content to users who have blocked the viewer
        if blockingInfo.isBlockedBy(sif.authorUid) {
            return false
        }
        
        return true
    }
    
    /// Get content visibility status for debugging
    static func getVisibilityStatus(_ sif: SIFItem, for userId: String, blockingInfo: UserBlockingInfo) -> ContentVisibilityStatus {
        if sif.isRemoved {
            return .removedByModerator
        }
        
        if blockingInfo.hasBlocked(sif.authorUid) {
            return .blockedByUser
        }
        
        if blockingInfo.isBlockedBy(sif.authorUid) {
            return .userBlockedByAuthor
        }
        
        return .visible
    }
}

enum ContentVisibilityStatus {
    case visible
    case removedByModerator
    case blockedByUser
    case userBlockedByAuthor
    
    var description: String {
        switch self {
        case .visible:
            return "Content is visible"
        case .removedByModerator:
            return "Content removed by moderator"
        case .blockedByUser:
            return "Content from blocked user"
        case .userBlockedByAuthor:
            return "User blocked by content author"
        }
    }
}