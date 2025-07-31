import Foundation

// MARK: - Notification settings model
struct NotificationSettings: Codable {
    var pushNotificationsEnabled: Bool
    var emailNotificationsEnabled: Bool
    var inAppAlertsEnabled: Bool
    
    // SIF-specific notifications
    var newSIFNotifications: Bool
    var sifDeliveredNotifications: Bool
    var sifOpenedNotifications: Bool
    var templateUpdateNotifications: Bool
    
    // Social notifications
    var friendRequestNotifications: Bool
    var messageNotifications: Bool
    var mentionNotifications: Bool
    
    // Marketing and updates
    var marketingEmails: Bool
    var productUpdates: Bool
    var weeklyDigest: Bool
    
    // Frequency controls
    var notificationFrequency: NotificationFrequency
    var quietHoursEnabled: Bool
    var quietHoursStart: String // "22:00"
    var quietHoursEnd: String   // "08:00"
    
    init() {
        self.pushNotificationsEnabled = true
        self.emailNotificationsEnabled = true
        self.inAppAlertsEnabled = true
        
        self.newSIFNotifications = true
        self.sifDeliveredNotifications = true
        self.sifOpenedNotifications = false
        self.templateUpdateNotifications = true
        
        self.friendRequestNotifications = true
        self.messageNotifications = true
        self.mentionNotifications = true
        
        self.marketingEmails = false
        self.productUpdates = true
        self.weeklyDigest = true
        
        self.notificationFrequency = .normal
        self.quietHoursEnabled = false
        self.quietHoursStart = "22:00"
        self.quietHoursEnd = "08:00"
    }
}

// MARK: - Notification frequency options
enum NotificationFrequency: String, Codable, CaseIterable {
    case immediate = "immediate"
    case normal = "normal"
    case digest = "digest"
    case minimal = "minimal"
    
    var displayName: String {
        switch self {
        case .immediate: return "Immediate"
        case .normal: return "Normal"
        case .digest: return "Daily Digest"
        case .minimal: return "Minimal"
        }
    }
}