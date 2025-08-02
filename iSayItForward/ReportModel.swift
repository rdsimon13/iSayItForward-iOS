import Foundation
import FirebaseFirestore

// MARK: - Report Categories
enum ReportCategory: String, CaseIterable, Codable {
    case spam = "spam"
    case harassment = "harassment"
    case inappropriateContent = "inappropriate_content"
    case falseInformation = "false_information"
    case copyright = "copyright"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .spam:
            return "Spam"
        case .harassment:
            return "Harassment"
        case .inappropriateContent:
            return "Inappropriate Content"
        case .falseInformation:
            return "False Information"
        case .copyright:
            return "Copyright Violation"
        case .other:
            return "Other"
        }
    }
    
    var description: String {
        switch self {
        case .spam:
            return "Unwanted or repetitive content"
        case .harassment:
            return "Bullying, threats, or harassment"
        case .inappropriateContent:
            return "Content that violates community guidelines"
        case .falseInformation:
            return "Misleading or false information"
        case .copyright:
            return "Unauthorized use of copyrighted material"
        case .other:
            return "Other violation not listed above"
        }
    }
}

// MARK: - Report Status
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

// MARK: - Report Model
struct Report: Identifiable, Codable, Hashable, Equatable {
    @DocumentID var id: String?
    
    let reporterUid: String
    let reportedContentId: String
    let reportedContentAuthorUid: String
    let category: ReportCategory
    let reason: String
    let createdDate: Date
    var status: ReportStatus
    var moderatorUid: String?
    var moderatorNotes: String?
    var reviewedDate: Date?
    
    // For hashable and equatable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Report, rhs: Report) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Blocked User Model
struct BlockedUser: Identifiable, Codable, Hashable, Equatable {
    @DocumentID var id: String?
    
    let blockerUid: String
    let blockedUid: String
    let blockedDate: Date
    let reason: String?
    
    // For hashable and equatable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: BlockedUser, rhs: BlockedUser) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Moderator Action Model
struct ModeratorAction: Identifiable, Codable {
    @DocumentID var id: String?
    
    let moderatorUid: String
    let reportId: String
    let action: String // "approved", "rejected", "dismissed"
    let notes: String?
    let actionDate: Date
}