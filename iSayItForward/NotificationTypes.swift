import Foundation
import SwiftUI

// MARK: - Core Notification Types
// These are the core dependency types required for the app's navigation and UI components

/// Defines the different types of notifications in the system
enum NotificationType: String, CaseIterable, Codable, Equatable {
    case sifReceived = "sif_received"
    case sifScheduled = "sif_scheduled"
    case sifDelivered = "sif_delivered"
    case reminder = "reminder"
    case systemUpdate = "system_update"
    case welcome = "welcome"
    
    /// Display name for UI
    var displayName: String {
        switch self {
        case .sifReceived:
            return "SIF Received"
        case .sifScheduled:
            return "SIF Scheduled"
        case .sifDelivered:
            return "SIF Delivered"
        case .reminder:
            return "Reminder"
        case .systemUpdate:
            return "System Update"
        case .welcome:
            return "Welcome"
        }
    }
    
    /// System icon for UI display
    var systemIcon: String {
        switch self {
        case .sifReceived:
            return "envelope.fill"
        case .sifScheduled:
            return "calendar.badge.clock"
        case .sifDelivered:
            return "paperplane.fill"
        case .reminder:
            return "bell.fill"
        case .systemUpdate:
            return "gear"
        case .welcome:
            return "hand.wave.fill"
        }
    }
    
    /// Default priority for this notification type
    var defaultPriority: NotificationPriority {
        switch self {
        case .sifReceived, .sifDelivered:
            return .high
        case .sifScheduled, .reminder:
            return .medium
        case .systemUpdate:
            return .low
        case .welcome:
            return .high
        }
    }
}

/// Defines the priority levels for notifications
enum NotificationPriority: Int, CaseIterable, Codable, Equatable, Comparable {
    case low = 1
    case medium = 2
    case high = 3
    case urgent = 4
    
    /// Display name for UI
    var displayName: String {
        switch self {
        case .low:
            return "Low"
        case .medium:
            return "Medium"
        case .high:
            return "High"
        case .urgent:
            return "Urgent"
        }
    }
    
    /// Color representation for UI
    var color: Color {
        switch self {
        case .low:
            return .gray
        case .medium:
            return .blue
        case .high:
            return .orange
        case .urgent:
            return .red
        }
    }
    
    /// Comparable conformance for sorting
    static func < (lhs: NotificationPriority, rhs: NotificationPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// Defines actions that can be taken on notifications
enum NotificationAction: String, CaseIterable, Codable, Equatable {
    case view = "view"
    case dismiss = "dismiss"
    case snooze = "snooze"
    case reply = "reply"
    case schedule = "schedule"
    case delete = "delete"
    case markAsRead = "mark_as_read"
    case share = "share"
    
    /// Display name for UI
    var displayName: String {
        switch self {
        case .view:
            return "View"
        case .dismiss:
            return "Dismiss"
        case .snooze:
            return "Snooze"
        case .reply:
            return "Reply"
        case .schedule:
            return "Schedule"
        case .delete:
            return "Delete"
        case .markAsRead:
            return "Mark as Read"
        case .share:
            return "Share"
        }
    }
    
    /// System icon for UI display
    var systemIcon: String {
        switch self {
        case .view:
            return "eye.fill"
        case .dismiss:
            return "xmark.circle.fill"
        case .snooze:
            return "clock.fill"
        case .reply:
            return "arrowshape.turn.up.left.fill"
        case .schedule:
            return "calendar.badge.plus"
        case .delete:
            return "trash.fill"
        case .markAsRead:
            return "checkmark.circle.fill"
        case .share:
            return "square.and.arrow.up.fill"
        }
    }
    
    /// Whether this action is destructive
    var isDestructive: Bool {
        switch self {
        case .delete:
            return true
        default:
            return false
        }
    }
    
    /// Static properties for common action sets used in menus
    static let primaryActions: [NotificationAction] = [.view, .markAsRead, .reply]
    static let secondaryActions: [NotificationAction] = [.snooze, .share, .schedule]
    static let destructiveActions: [NotificationAction] = [.dismiss, .delete]
    static let allActions: [NotificationAction] = primaryActions + secondaryActions + destructiveActions
}

/// Represents a notification item in the system
struct NotificationItem: Identifiable, Codable, Hashable, Equatable {
    /// Unique identifier for the notification
    let id: UUID
    
    /// Type of notification
    let type: NotificationType
    
    /// Priority level
    let priority: NotificationPriority
    
    /// Notification title
    let title: String
    
    /// Notification message/body
    let message: String
    
    /// When the notification was created
    let createdDate: Date
    
    /// When the notification should be displayed (for scheduled notifications)
    let scheduledDate: Date?
    
    /// Whether the notification has been read
    var isRead: Bool
    
    /// Associated SIF ID if applicable
    let sifId: String?
    
    /// Additional metadata
    let metadata: [String: String]?
    
    /// Initializer with defaults
    init(
        id: UUID = UUID(),
        type: NotificationType,
        priority: NotificationPriority? = nil,
        title: String,
        message: String,
        createdDate: Date = Date(),
        scheduledDate: Date? = nil,
        isRead: Bool = false,
        sifId: String? = nil,
        metadata: [String: String]? = nil
    ) {
        self.id = id
        self.type = type
        self.priority = priority ?? type.defaultPriority
        self.title = title
        self.message = message
        self.createdDate = createdDate
        self.scheduledDate = scheduledDate
        self.isRead = isRead
        self.sifId = sifId
        self.metadata = metadata
    }
    
    /// Whether this notification is scheduled for the future
    var isScheduled: Bool {
        guard let scheduledDate = scheduledDate else { return false }
        return scheduledDate > Date()
    }
    
    /// Whether this notification is overdue
    var isOverdue: Bool {
        guard let scheduledDate = scheduledDate else { return false }
        return scheduledDate < Date() && !isRead
    }
    
    /// Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    /// Equatable conformance
    static func == (lhs: NotificationItem, rhs: NotificationItem) -> Bool {
        lhs.id == rhs.id
    }
}