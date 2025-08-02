import Foundation
import FirebaseFirestore

/// Represents a content report made by a user
struct ReportItem: Identifiable, Codable {
    @DocumentID var id: String?
    
    let reporterId: String          // UID of the user making the report
    let reportedContentId: String   // ID of the SIF being reported
    let reportedUserId: String      // UID of the user who created the content
    let reason: ReportReason        // Reason for the report
    let description: String?        // Optional additional description
    let timestamp: Date             // When the report was made
    var status: ReportStatus        // Current status of the report
    var moderatorId: String?        // UID of moderator who handled the report
    var moderatorNotes: String?     // Notes from the moderator
    var actionTaken: ModerationAction? // Action taken by moderator
    var resolvedDate: Date?         // When the report was resolved
}

/// Reasons for reporting content
enum ReportReason: String, CaseIterable, Codable {
    case inappropriateContent = "inappropriate_content"
    case harassment = "harassment"
    case spam = "spam"
    case hateSpeech = "hate_speech"
    case violence = "violence"
    case misinformation = "misinformation"
    case copyright = "copyright"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .inappropriateContent:
            return "Inappropriate Content"
        case .harassment:
            return "Harassment or Bullying"
        case .spam:
            return "Spam"
        case .hateSpeech:
            return "Hate Speech"
        case .violence:
            return "Violence or Threats"
        case .misinformation:
            return "Misinformation"
        case .copyright:
            return "Copyright Violation"
        case .other:
            return "Other"
        }
    }
    
    var description: String {
        switch self {
        case .inappropriateContent:
            return "Content that is offensive or inappropriate"
        case .harassment:
            return "Bullying, harassment, or targeting individuals"
        case .spam:
            return "Unwanted repetitive or promotional content"
        case .hateSpeech:
            return "Content promoting hatred toward groups"
        case .violence:
            return "Threats or promotion of violence"
        case .misinformation:
            return "False or misleading information"
        case .copyright:
            return "Unauthorized use of copyrighted material"
        case .other:
            return "Other policy violation"
        }
    }
}

/// Status of a content report
enum ReportStatus: String, Codable {
    case pending = "pending"
    case underReview = "under_review"
    case resolved = "resolved"
    case dismissed = "dismissed"
    
    var displayName: String {
        switch self {
        case .pending:
            return "Pending"
        case .underReview:
            return "Under Review"
        case .resolved:
            return "Resolved"
        case .dismissed:
            return "Dismissed"
        }
    }
}

/// Actions that can be taken by moderators
enum ModerationAction: String, Codable {
    case noAction = "no_action"
    case contentRemoved = "content_removed"
    case userWarned = "user_warned"
    case userSuspended = "user_suspended"
    case userBanned = "user_banned"
    
    var displayName: String {
        switch self {
        case .noAction:
            return "No Action Required"
        case .contentRemoved:
            return "Content Removed"
        case .userWarned:
            return "User Warned"
        case .userSuspended:
            return "User Suspended"
        case .userBanned:
            return "User Banned"
        }
    }
}