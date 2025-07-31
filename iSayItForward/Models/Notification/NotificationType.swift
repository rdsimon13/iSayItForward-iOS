import Foundation

// MARK: - Notification Type
enum NotificationType: String, Codable, CaseIterable {
    // SIF-related notifications
    case sifReceived = "sif_received"
    case sifDelivered = "sif_delivered"
    case sifScheduled = "sif_scheduled"
    case sifReminder = "sif_reminder"
    
    // Social notifications
    case friendRequest = "friend_request"
    case friendAccepted = "friend_accepted"
    case messageReceived = "message_received"
    
    // System notifications
    case systemUpdate = "system_update"
    case accountUpdate = "account_update"
    case securityAlert = "security_alert"
    
    // Template notifications
    case templateShared = "template_shared"
    case templateUpdated = "template_updated"
    
    // Achievement notifications
    case achievement = "achievement"
    case milestone = "milestone"
    
    var displayName: String {
        switch self {
        case .sifReceived: return "SIF Received"
        case .sifDelivered: return "SIF Delivered"
        case .sifScheduled: return "SIF Scheduled"
        case .sifReminder: return "SIF Reminder"
        case .friendRequest: return "Friend Request"
        case .friendAccepted: return "Friend Accepted"
        case .messageReceived: return "Message Received"
        case .systemUpdate: return "System Update"
        case .accountUpdate: return "Account Update"
        case .securityAlert: return "Security Alert"
        case .templateShared: return "Template Shared"
        case .templateUpdated: return "Template Updated"
        case .achievement: return "Achievement"
        case .milestone: return "Milestone"
        }
    }
    
    var iconName: String {
        switch self {
        case .sifReceived: return "envelope.fill"
        case .sifDelivered: return "checkmark.circle.fill"
        case .sifScheduled: return "calendar"
        case .sifReminder: return "bell.fill"
        case .friendRequest: return "person.badge.plus"
        case .friendAccepted: return "person.2.fill"
        case .messageReceived: return "message.fill"
        case .systemUpdate: return "gear"
        case .accountUpdate: return "person.circle.fill"
        case .securityAlert: return "exclamationmark.shield.fill"
        case .templateShared: return "doc.on.doc"
        case .templateUpdated: return "doc.badge.plus"
        case .achievement: return "star.fill"
        case .milestone: return "flag.fill"
        }
    }
    
    var category: NotificationCategory {
        switch self {
        case .sifReceived, .sifDelivered, .sifScheduled, .sifReminder:
            return .sif
        case .friendRequest, .friendAccepted, .messageReceived:
            return .social
        case .systemUpdate, .accountUpdate, .securityAlert:
            return .system
        case .templateShared, .templateUpdated:
            return .template
        case .achievement, .milestone:
            return .achievement
        }
    }
    
    var defaultPriority: NotificationPriority {
        switch self {
        case .securityAlert:
            return .critical
        case .sifReceived, .friendRequest, .messageReceived:
            return .high
        case .sifDelivered, .sifReminder, .friendAccepted:
            return .normal
        default:
            return .low
        }
    }
    
    var allowsActions: Bool {
        switch self {
        case .sifReceived, .friendRequest, .messageReceived:
            return true
        default:
            return false
        }
    }
}

// MARK: - Notification Category
enum NotificationCategory: String, Codable, CaseIterable {
    case sif = "sif"
    case social = "social"
    case system = "system"
    case template = "template"
    case achievement = "achievement"
    
    var displayName: String {
        switch self {
        case .sif: return "SIF"
        case .social: return "Social"
        case .system: return "System"
        case .template: return "Templates"
        case .achievement: return "Achievements"
        }
    }
    
    var color: String {
        switch self {
        case .sif: return "blue"
        case .social: return "green"
        case .system: return "orange"
        case .template: return "purple"
        case .achievement: return "yellow"
        }
    }
}