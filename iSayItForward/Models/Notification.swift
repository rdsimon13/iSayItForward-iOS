import Foundation
import FirebaseFirestore

// MARK: - Core Notification Model
struct Notification: Identifiable, Codable, Hashable, Equatable {
    @DocumentID var id: String?
    
    let userId: String
    let type: NotificationType
    let title: String
    let message: String
    let createdDate: Date
    var isRead: Bool
    var isSilent: Bool
    
    // Optional data for specific notification types
    var relatedSIFId: String?
    var actionData: [String: String]?
    var imageURL: String?
    var deepLinkURL: String?
    
    // Grouping and categorization
    var groupId: String?
    var category: String?
    var priority: NotificationPriority
    
    // Push notification related
    var pushNotificationId: String?
    var shouldShowBadge: Bool
    
    init(
        userId: String,
        type: NotificationType,
        title: String,
        message: String,
        isRead: Bool = false,
        isSilent: Bool = false,
        priority: NotificationPriority = .normal,
        shouldShowBadge: Bool = true
    ) {
        self.userId = userId
        self.type = type
        self.title = title
        self.message = message
        self.createdDate = Date()
        self.isRead = isRead
        self.isSilent = isSilent
        self.priority = priority
        self.shouldShowBadge = shouldShowBadge
    }
    
    // MARK: - Hashable & Equatable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Notification, rhs: Notification) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Notification Priority
enum NotificationPriority: String, Codable, CaseIterable {
    case low = "low"
    case normal = "normal"
    case high = "high"
    case urgent = "urgent"
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .normal: return "Normal"
        case .high: return "High"
        case .urgent: return "Urgent"
        }
    }
    
    var badgeCount: Int {
        switch self {
        case .low: return 0
        case .normal: return 1
        case .high: return 1
        case .urgent: return 1
        }
    }
}