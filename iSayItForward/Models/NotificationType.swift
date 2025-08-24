import Foundation

// MARK: - Notification Type Enumeration
enum NotificationType: String, Codable, CaseIterable {
    case messageResponse = "message_response"
    case impactMilestone = "impact_milestone"
    case mention = "mention"
    case systemNotification = "system_notification"
    case communityUpdate = "community_update"
    case sifDelivered = "sif_delivered"
    case sifReceived = "sif_received"
    case reminderScheduled = "reminder_scheduled"
    case accountUpdate = "account_update"
    case newFeature = "new_feature"
    
    var displayName: String {
        switch self {
        case .messageResponse:
            return "Message Response"
        case .impactMilestone:
            return "Impact Milestone"
        case .mention:
            return "Mention"
        case .systemNotification:
            return "System Notification"
        case .communityUpdate:
            return "Community Update"
        case .sifDelivered:
            return "SIF Delivered"
        case .sifReceived:
            return "SIF Received"
        case .reminderScheduled:
            return "Reminder"
        case .accountUpdate:
            return "Account Update"
        case .newFeature:
            return "New Feature"
        }
    }
    
    var iconName: String {
        switch self {
        case .messageResponse:
            return "bubble.left.and.bubble.right"
        case .impactMilestone:
            return "trophy"
        case .mention:
            return "at"
        case .systemNotification:
            return "gear"
        case .communityUpdate:
            return "person.3"
        case .sifDelivered:
            return "paperplane"
        case .sifReceived:
            return "envelope"
        case .reminderScheduled:
            return "clock"
        case .accountUpdate:
            return "person.circle"
        case .newFeature:
            return "sparkles"
        }
    }
    
    var color: String {
        switch self {
        case .messageResponse:
            return "blue"
        case .impactMilestone:
            return "orange"
        case .mention:
            return "purple"
        case .systemNotification:
            return "gray"
        case .communityUpdate:
            return "green"
        case .sifDelivered:
            return "blue"
        case .sifReceived:
            return "teal"
        case .reminderScheduled:
            return "yellow"
        case .accountUpdate:
            return "indigo"
        case .newFeature:
            return "pink"
        }
    }
    
    var category: NotificationCategory {
        switch self {
        case .messageResponse, .sifDelivered, .sifReceived:
            return .messages
        case .impactMilestone:
            return .milestones
        case .mention:
            return .social
        case .systemNotification, .accountUpdate:
            return .system
        case .communityUpdate:
            return .community
        case .reminderScheduled:
            return .reminders
        case .newFeature:
            return .updates
        }
    }
    
    var priority: NotificationPriority {
        switch self {
        case .messageResponse, .mention, .sifReceived:
            return .high
        case .impactMilestone, .reminderScheduled:
            return .normal
        case .systemNotification, .accountUpdate, .newFeature:
            return .normal
        case .communityUpdate, .sifDelivered:
            return .low
        }
    }
}

// MARK: - Notification Category
enum NotificationCategory: String, Codable, CaseIterable {
    case messages = "messages"
    case milestones = "milestones"
    case social = "social"
    case system = "system"
    case community = "community"
    case reminders = "reminders"
    case updates = "updates"
    
    var displayName: String {
        switch self {
        case .messages: return "Messages"
        case .milestones: return "Milestones"
        case .social: return "Social"
        case .system: return "System"
        case .community: return "Community"
        case .reminders: return "Reminders"
        case .updates: return "Updates"
        }
    }
    
    var iconName: String {
        switch self {
        case .messages: return "envelope.fill"
        case .milestones: return "trophy.fill"
        case .social: return "person.2.fill"
        case .system: return "gear.circle.fill"
        case .community: return "person.3.fill"
        case .reminders: return "clock.fill"
        case .updates: return "arrow.down.circle.fill"
        }
    }
}