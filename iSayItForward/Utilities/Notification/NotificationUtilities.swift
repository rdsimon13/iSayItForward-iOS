import Foundation
import UserNotifications
import UIKit

// MARK: - Notification Utilities
struct NotificationUtilities {
    
    // MARK: - Date Formatting
    static func formatNotificationDate(_ date: Date) -> String {
        let now = Date()
        let calendar = Calendar.current
        
        if calendar.isToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: date)
        } else if calendar.isYesterday(date) {
            return "Yesterday"
        } else if calendar.component(.year, from: date) == calendar.component(.year, from: now) {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: date)
        }
    }
    
    static func formatRelativeTime(_ date: Date) -> String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        
        if timeInterval < 60 {
            return "Just now"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)m ago"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(timeInterval / 86400)
            if days == 1 {
                return "1 day ago"
            } else if days < 7 {
                return "\(days) days ago"
            } else {
                return formatNotificationDate(date)
            }
        }
    }
    
    // MARK: - Text Processing
    static func truncateText(_ text: String, maxLength: Int = 100) -> String {
        if text.count <= maxLength {
            return text
        }
        
        let truncated = String(text.prefix(maxLength))
        if let lastSpace = truncated.lastIndex(of: " ") {
            return String(truncated[..<lastSpace]) + "..."
        } else {
            return truncated + "..."
        }
    }
    
    static func extractMentions(from text: String) -> [String] {
        let pattern = "@([A-Za-z0-9_]+)"
        let regex = try? NSRegularExpression(pattern: pattern)
        let matches = regex?.matches(in: text, range: NSRange(text.startIndex..., in: text)) ?? []
        
        return matches.compactMap { match in
            if let range = Range(match.range(at: 1), in: text) {
                return String(text[range])
            }
            return nil
        }
    }
    
    static func extractHashtags(from text: String) -> [String] {
        let pattern = "#([A-Za-z0-9_]+)"
        let regex = try? NSRegularExpression(pattern: pattern)
        let matches = regex?.matches(in: text, range: NSRange(text.startIndex..., in: text)) ?? []
        
        return matches.compactMap { match in
            if let range = Range(match.range(at: 1), in: text) {
                return String(text[range])
            }
            return nil
        }
    }
    
    // MARK: - Badge Utilities
    static func updateAppBadge(count: Int) {
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = count
        }
    }
    
    static func clearAppBadge() {
        updateAppBadge(count: 0)
    }
    
    // MARK: - Permission Utilities
    static func openNotificationSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    // MARK: - Deep Link Utilities
    static func parseDeepLink(_ url: String) -> (path: String, parameters: [String: String])? {
        guard let url = URL(string: url),
              url.scheme == NotificationConstants.DeepLinks.scheme else {
            return nil
        }
        
        let path = url.host ?? ""
        var parameters: [String: String] = [:]
        
        // Parse path components
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        if pathComponents.count > 0 {
            parameters["id"] = pathComponents[0]
        }
        
        // Parse query parameters
        if let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems {
            for item in queryItems {
                parameters[item.name] = item.value
            }
        }
        
        return (path, parameters)
    }
    
    static func isValidDeepLink(_ url: String) -> Bool {
        return parseDeepLink(url) != nil
    }
    
    // MARK: - Analytics Utilities
    static func logNotificationEvent(_ event: NotificationEvent, notification: Notification) {
        let parameters: [String: Any] = [
            "notification_id": notification.id,
            "notification_type": notification.type.rawValue,
            "notification_priority": notification.priority.rawValue,
            "event_type": event.rawValue,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        // In a real app, you would send this to your analytics service
        print("📊 Notification Analytics: \(event.rawValue) - \(notification.type.displayName)")
        print("📊 Parameters: \(parameters)")
    }
    
    // MARK: - Validation Utilities
    static func validateNotificationPayload(_ payload: NotificationPayload) -> Bool {
        // Basic validation - in a real app, you might have more complex rules
        if let sifId = payload.sifId, sifId.isEmpty {
            return false
        }
        
        if let senderId = payload.senderId, senderId.isEmpty {
            return false
        }
        
        if let deepLink = payload.deepLink, !isValidDeepLink(deepLink) {
            return false
        }
        
        return true
    }
    
    static func sanitizeNotificationContent(_ content: String) -> String {
        // Remove potentially harmful content
        var sanitized = content
        
        // Remove excessive whitespace
        sanitized = sanitized.trimmingCharacters(in: .whitespacesAndNewlines)
        sanitized = sanitized.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        // Remove potential script tags or suspicious content
        let scriptPattern = "<script[^>]*>.*?</script>"
        sanitized = sanitized.replacingOccurrences(of: scriptPattern, with: "", options: [.regularExpression, .caseInsensitive])
        
        return sanitized
    }
    
    // MARK: - Grouping Utilities
    static func groupNotifications(_ notifications: [Notification]) -> [String: [Notification]] {
        return Dictionary(grouping: notifications) { notification in
            if Calendar.current.isToday(notification.createdAt) {
                return "Today"
            } else if Calendar.current.isYesterday(notification.createdAt) {
                return "Yesterday"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM d, yyyy"
                return formatter.string(from: notification.createdAt)
            }
        }
    }
    
    static func groupNotificationsByType(_ notifications: [Notification]) -> [NotificationCategory: [Notification]] {
        return Dictionary(grouping: notifications) { $0.type.category }
    }
    
    // MARK: - Sound Utilities
    static func playSoundForNotificationType(_ type: NotificationType) {
        let soundName: String
        
        switch type {
        case .sifReceived:
            soundName = NotificationConstants.Sounds.sifReceived
        case .friendRequest:
            soundName = NotificationConstants.Sounds.friendRequest
        case .messageReceived:
            soundName = NotificationConstants.Sounds.messageReceived
        case .achievement, .milestone:
            soundName = NotificationConstants.Sounds.achievement
        case .securityAlert, .systemUpdate:
            soundName = NotificationConstants.Sounds.systemAlert
        default:
            soundName = NotificationConstants.Sounds.defaultSound
        }
        
        // In a real app, you would play the actual sound file
        print("🔊 Playing notification sound: \(soundName)")
    }
}

// MARK: - Notification Event Types
enum NotificationEvent: String, CaseIterable {
    case received = "received"
    case viewed = "viewed"
    case clicked = "clicked"
    case dismissed = "dismissed"
    case actionTaken = "action_taken"
    case delivered = "delivered"
    case failed = "failed"
    case scheduled = "scheduled"
    case cancelled = "cancelled"
}

// MARK: - Notification Helper Extensions
extension Array where Element == Notification {
    var unreadCount: Int {
        return filter { !$0.isRead }.count
    }
    
    var priorityNotificationsCount: Int {
        return filter { $0.priority == .high || $0.priority == .critical }.count
    }
    
    func filteredBy(category: NotificationCategory) -> [Notification] {
        return filter { $0.type.category == category }
    }
    
    func filteredBy(priority: NotificationPriority) -> [Notification] {
        return filter { $0.priority == priority }
    }
    
    func sortedByPriority() -> [Notification] {
        return sorted { first, second in
            if first.priority == second.priority {
                return first.createdAt > second.createdAt
            }
            
            let priorityOrder: [NotificationPriority] = [.critical, .high, .normal, .low]
            let firstIndex = priorityOrder.firstIndex(of: first.priority) ?? priorityOrder.count
            let secondIndex = priorityOrder.firstIndex(of: second.priority) ?? priorityOrder.count
            
            return firstIndex < secondIndex
        }
    }
}