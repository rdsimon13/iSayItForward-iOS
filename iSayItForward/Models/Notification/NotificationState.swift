import Foundation

// MARK: - Notification State
enum NotificationState: String, Codable, CaseIterable {
    case pending = "pending"
    case sent = "sent"
    case delivered = "delivered"
    case read = "read"
    case failed = "failed"
    case cancelled = "cancelled"
    case archived = "archived"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .sent: return "Sent"
        case .delivered: return "Delivered"
        case .read: return "Read"
        case .failed: return "Failed"
        case .cancelled: return "Cancelled"
        case .archived: return "Archived"
        }
    }
    
    var iconName: String {
        switch self {
        case .pending: return "clock"
        case .sent: return "paperplane"
        case .delivered: return "checkmark.circle"
        case .read: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.triangle"
        case .cancelled: return "xmark.circle"
        case .archived: return "archivebox"
        }
    }
    
    var color: String {
        switch self {
        case .pending: return "orange"
        case .sent: return "blue"
        case .delivered: return "green"
        case .read: return "gray"
        case .failed: return "red"
        case .cancelled: return "red"
        case .archived: return "gray"
        }
    }
    
    var isActive: Bool {
        switch self {
        case .pending, .sent, .delivered:
            return true
        case .read, .failed, .cancelled, .archived:
            return false
        }
    }
    
    var canRetry: Bool {
        return self == .failed
    }
    
    var canCancel: Bool {
        return self == .pending
    }
    
    var canArchive: Bool {
        switch self {
        case .read, .delivered:
            return true
        default:
            return false
        }
    }
}

// MARK: - Notification Filter
enum NotificationFilter: String, CaseIterable {
    case all = "all"
    case unread = "unread"
    case read = "read"
    case archived = "archived"
    case failed = "failed"
    case scheduled = "scheduled"
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .unread: return "Unread"
        case .read: return "Read"
        case .archived: return "Archived"
        case .failed: return "Failed"
        case .scheduled: return "Scheduled"
        }
    }
    
    var iconName: String {
        switch self {
        case .all: return "list.bullet"
        case .unread: return "envelope.badge"
        case .read: return "envelope.open"
        case .archived: return "archivebox"
        case .failed: return "exclamationmark.triangle"
        case .scheduled: return "calendar.badge.clock"
        }
    }
}

// MARK: - Notification Sort
enum NotificationSort: String, CaseIterable {
    case newest = "newest"
    case oldest = "oldest"
    case priority = "priority"
    case type = "type"
    
    var displayName: String {
        switch self {
        case .newest: return "Newest First"
        case .oldest: return "Oldest First"
        case .priority: return "By Priority"
        case .type: return "By Type"
        }
    }
}