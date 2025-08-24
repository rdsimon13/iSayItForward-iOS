import Foundation

// MARK: - Core Notification Model
struct Notification: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let body: String
    let type: NotificationType
    let payload: NotificationPayload?
    let createdAt: Date
    let scheduledAt: Date?
    var isRead: Bool
    var state: NotificationState
    let senderUID: String?
    let recipientUID: String
    let priority: NotificationPriority
    let actions: [NotificationAction]
    
    init(
        id: String = UUID().uuidString,
        title: String,
        body: String,
        type: NotificationType,
        payload: NotificationPayload? = nil,
        createdAt: Date = Date(),
        scheduledAt: Date? = nil,
        isRead: Bool = false,
        state: NotificationState = .pending,
        senderUID: String? = nil,
        recipientUID: String,
        priority: NotificationPriority = .normal,
        actions: [NotificationAction] = []
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.type = type
        self.payload = payload
        self.createdAt = createdAt
        self.scheduledAt = scheduledAt
        self.isRead = isRead
        self.state = state
        self.senderUID = senderUID
        self.recipientUID = recipientUID
        self.priority = priority
        self.actions = actions
    }
}

// MARK: - Notification Priority
enum NotificationPriority: String, Codable, CaseIterable {
    case low = "low"
    case normal = "normal"
    case high = "high"
    case critical = "critical"
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .normal: return "Normal"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }
    
    var badgeColor: String {
        switch self {
        case .low: return "gray"
        case .normal: return "blue"
        case .high: return "orange"
        case .critical: return "red"
        }
    }
}

// MARK: - Notification Extensions
extension Notification {
    var isScheduled: Bool {
        return scheduledAt != nil && scheduledAt! > Date()
    }
    
    var isOverdue: Bool {
        guard let scheduledAt = scheduledAt else { return false }
        return scheduledAt < Date() && state == .pending
    }
    
    var displayTime: String {
        let formatter = DateFormatter()
        if Calendar.current.isToday(createdAt) {
            formatter.dateFormat = "h:mm a"
        } else if Calendar.current.isYesterday(createdAt) {
            return "Yesterday"
        } else {
            formatter.dateFormat = "MMM d"
        }
        return formatter.string(from: createdAt)
    }
    
    mutating func markAsRead() {
        isRead = true
    }
    
    mutating func updateState(_ newState: NotificationState) {
        state = newState
    }
}