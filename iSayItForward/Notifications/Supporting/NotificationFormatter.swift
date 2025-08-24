import Foundation

// MARK: - Notification Formatter
struct NotificationFormatter {
    
    // MARK: - Time Formatting
    static func formatTime(from date: Date) -> String {
        let now = Date()
        let calendar = Calendar.current
        let timeInterval = now.timeIntervalSince(date)
        
        if timeInterval < 60 {
            return "Just now"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)m ago"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)h ago"
        } else if calendar.isDateInYesterday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return "Yesterday \(formatter.string(from: date))"
        } else if timeInterval < 604800 { // Within a week
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE h:mm a"
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, h:mm a"
            return formatter.string(from: date)
        }
    }
    
    static func formatRelativeTime(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    static func formatFullDateTime(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // MARK: - Title and Message Formatting
    static func formatTitle(for notification: Notification) -> String {
        switch notification.type {
        case .messageResponse:
            return "New Response"
        case .impactMilestone:
            return "Milestone Reached!"
        case .mention:
            return "You were mentioned"
        case .systemNotification:
            return "System Update"
        case .communityUpdate:
            return "Community News"
        case .sifDelivered:
            return "SIF Delivered"
        case .sifReceived:
            return "New SIF Received"
        case .reminderScheduled:
            return "Reminder"
        case .accountUpdate:
            return "Account Update"
        case .newFeature:
            return "New Feature Available"
        }
    }
    
    static func formatMessage(for notification: Notification, truncateAt: Int = 120) -> String {
        let message = notification.message
        if message.count <= truncateAt {
            return message
        } else {
            let truncated = String(message.prefix(truncateAt))
            return "\(truncated)..."
        }
    }
    
    static func formatSubtitle(for notification: Notification) -> String? {
        switch notification.type {
        case .messageResponse, .mention:
            if let relatedSIFId = notification.relatedSIFId {
                return "RE: SIF #\(relatedSIFId.prefix(8))"
            }
            return nil
        case .impactMilestone:
            return "Your impact is growing!"
        case .sifDelivered:
            return "Successfully delivered"
        case .sifReceived:
            return "From your network"
        case .reminderScheduled:
            return "Don't forget"
        case .communityUpdate:
            return "iSayItForward Community"
        case .systemNotification, .accountUpdate, .newFeature:
            return "iSayItForward"
        }
    }
    
    // MARK: - Badge Formatting
    static func formatBadgeCount(_ count: Int) -> String {
        if count > 99 {
            return "99+"
        } else if count > 0 {
            return "\(count)"
        } else {
            return ""
        }
    }
    
    // MARK: - Grouping and Summary
    static func formatGroupSummary(notifications: [Notification]) -> String {
        let count = notifications.count
        
        if count <= 1 {
            return ""
        }
        
        // Group by type
        let typeGroups = Dictionary(grouping: notifications) { $0.type }
        
        if typeGroups.count == 1, let type = typeGroups.keys.first {
            switch type {
            case .messageResponse:
                return "\(count) new responses"
            case .impactMilestone:
                return "\(count) milestones reached"
            case .mention:
                return "\(count) new mentions"
            case .sifReceived:
                return "\(count) new SIFs"
            case .sifDelivered:
                return "\(count) SIFs delivered"
            case .reminderScheduled:
                return "\(count) reminders"
            default:
                return "\(count) notifications"
            }
        } else {
            return "\(count) notifications"
        }
    }
    
    static func formatNotificationSummary(for notifications: [Notification]) -> String {
        let unreadCount = notifications.filter { !$0.isRead }.count
        let totalCount = notifications.count
        
        if unreadCount == 0 {
            return totalCount == 1 ? "1 notification" : "\(totalCount) notifications"
        } else if unreadCount == totalCount {
            return unreadCount == 1 ? "1 new notification" : "\(unreadCount) new notifications"
        } else {
            return "\(unreadCount) new, \(totalCount) total"
        }
    }
    
    // MARK: - Action Formatting
    static func formatActionTitle(for action: NotificationAction, context: String? = nil) -> String {
        switch action.type {
        case .reply:
            return "Reply"
        case .view:
            return context ?? "View"
        case .dismiss:
            return "Dismiss"
        case .markAsRead:
            return "Mark as Read"
        case .delete:
            return "Delete"
        case .share:
            return "Share"
        case .archive:
            return "Archive"
        case .openSIF:
            return "Open SIF"
        case .openProfile:
            return "View Profile"
        case .navigateToScreen:
            return context ?? "Go"
        case .openURL:
            return "Open Link"
        case .scheduleReminder:
            return "Remind Me"
        case .customAction:
            return action.title
        }
    }
    
    // MARK: - Push Notification Formatting
    static func formatPushNotificationPayload(for notification: Notification) -> [String: Any] {
        var payload: [String: Any] = [:]
        
        // Basic notification content
        payload["title"] = formatTitle(for: notification)
        payload["body"] = formatMessage(for: notification, truncateAt: 200)
        
        if let subtitle = formatSubtitle(for: notification) {
            payload["subtitle"] = subtitle
        }
        
        // Custom data
        var customData: [String: Any] = [:]
        customData[NotificationConstants.PayloadKeys.notificationId] = notification.id
        customData[NotificationConstants.PayloadKeys.notificationType] = notification.type.rawValue
        customData[NotificationConstants.PayloadKeys.userId] = notification.userId
        
        if let relatedSIFId = notification.relatedSIFId {
            customData[NotificationConstants.PayloadKeys.sifId] = relatedSIFId
        }
        
        if let deepLinkURL = notification.deepLinkURL {
            customData[NotificationConstants.PayloadKeys.deepLinkURL] = deepLinkURL
        }
        
        if let groupId = notification.groupId {
            customData[NotificationConstants.PayloadKeys.groupId] = groupId
        }
        
        customData[NotificationConstants.PayloadKeys.priority] = notification.priority.rawValue
        customData[NotificationConstants.PayloadKeys.isSilent] = notification.isSilent
        
        payload["custom_data"] = customData
        
        // Badge and sound
        if notification.shouldShowBadge {
            payload["badge"] = 1
        }
        
        if !notification.isSilent {
            payload["sound"] = "default"
        }
        
        return payload
    }
    
    // MARK: - Preview Text Formatting
    static func formatPreviewText(for notification: Notification, maxLength: Int = 50) -> String {
        let message = notification.message.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if message.count <= maxLength {
            return message
        } else {
            let truncated = String(message.prefix(maxLength))
            return "\(truncated)..."
        }
    }
    
    // MARK: - Category Display Names
    static func formatCategoryDisplayName(for category: NotificationCategory) -> String {
        return category.displayName
    }
    
    static func formatTypeDisplayName(for type: NotificationType) -> String {
        return type.displayName
    }
}