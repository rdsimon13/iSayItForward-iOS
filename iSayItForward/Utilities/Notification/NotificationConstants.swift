import Foundation

// MARK: - Notification Constants
struct NotificationConstants {
    
    // MARK: - Permissions
    struct Permissions {
        static let requestTitle = "Enable Notifications"
        static let requestMessage = "Stay updated with your SIFs, messages, and important updates."
        static let settingsTitle = "Notification Settings"
        static let settingsMessage = "To receive notifications, please enable them in Settings."
        static let settingsButtonTitle = "Open Settings"
    }
    
    // MARK: - Limits
    struct Limits {
        static let maxNotificationsPerUser = 1000
        static let maxDailyNotifications = 50
        static let maxRetryAttempts = 3
        static let retryDelaySeconds: TimeInterval = 5.0
        static let notificationExpirationDays = 30
        static let batchProcessingSize = 20
    }
    
    // MARK: - Deep Link Schemes
    struct DeepLinks {
        static let scheme = "isayitforward"
        static let sifPath = "sif"
        static let profilePath = "profile"
        static let chatPath = "chat"
        static let templatePath = "template"
        static let achievementPath = "achievement"
        static let settingsPath = "settings"
        
        static func sifURL(id: String) -> String {
            return "\(scheme)://\(sifPath)/\(id)"
        }
        
        static func profileURL(userID: String) -> String {
            return "\(scheme)://\(profilePath)/\(userID)"
        }
        
        static func chatURL(chatID: String) -> String {
            return "\(scheme)://\(chatPath)/\(chatID)"
        }
        
        static func templateURL(templateID: String) -> String {
            return "\(scheme)://\(templatePath)/\(templateID)"
        }
        
        static func achievementURL(achievementID: String) -> String {
            return "\(scheme)://\(achievementPath)/\(achievementID)"
        }
    }
    
    // MARK: - Notification Categories
    struct Categories {
        static let sifReceived = "SIF_RECEIVED"
        static let friendRequest = "FRIEND_REQUEST"
        static let messageReceived = "MESSAGE_RECEIVED"
        static let systemAlert = "SYSTEM_ALERT"
        static let achievement = "ACHIEVEMENT"
    }
    
    // MARK: - Action Identifiers
    struct ActionIdentifiers {
        static let reply = "REPLY_ACTION"
        static let accept = "ACCEPT_ACTION"
        static let decline = "DECLINE_ACTION"
        static let view = "VIEW_ACTION"
        static let delete = "DELETE_ACTION"
        static let archive = "ARCHIVE_ACTION"
        static let markRead = "MARK_READ_ACTION"
        static let openSIF = "OPEN_SIF_ACTION"
        static let openProfile = "OPEN_PROFILE_ACTION"
        static let openChat = "OPEN_CHAT_ACTION"
    }
    
    // MARK: - Sound Files
    struct Sounds {
        static let sifReceived = "sif_received.wav"
        static let friendRequest = "friend_request.wav"
        static let messageReceived = "message_received.wav"
        static let achievement = "achievement.wav"
        static let systemAlert = "system_alert.wav"
        static let defaultSound = "default.wav"
    }
    
    // MARK: - Badge Colors
    struct BadgeColors {
        static let unread = "blue"
        static let priority = "red"
        static let friend = "green"
        static let system = "orange"
        static let achievement = "yellow"
        static let template = "purple"
    }
    
    // MARK: - Animation Durations
    struct Animations {
        static let badgeAppear: TimeInterval = 0.3
        static let badgeDisappear: TimeInterval = 0.2
        static let listItemAppear: TimeInterval = 0.5
        static let markAsReadTransition: TimeInterval = 0.3
        static let deleteTransition: TimeInterval = 0.4
        static let refreshIndicator: TimeInterval = 1.0
    }
    
    // MARK: - User Default Keys
    struct UserDefaultsKeys {
        static let notificationsEnabled = "notifications_enabled"
        static let soundEnabled = "notification_sound_enabled"
        static let badgeEnabled = "notification_badge_enabled"
        static let sifNotificationsEnabled = "sif_notifications_enabled"
        static let socialNotificationsEnabled = "social_notifications_enabled"
        static let systemNotificationsEnabled = "system_notifications_enabled"
        static let quietHoursEnabled = "quiet_hours_enabled"
        static let quietHoursStart = "quiet_hours_start"
        static let quietHoursEnd = "quiet_hours_end"
        static let lastNotificationCleanup = "last_notification_cleanup"
    }
    
    // MARK: - API Endpoints (for future backend integration)
    struct APIEndpoints {
        static let registerToken = "/api/notifications/register-token"
        static let sendNotification = "/api/notifications/send"
        static let markAsRead = "/api/notifications/mark-read"
        static let getNotifications = "/api/notifications"
        static let updatePreferences = "/api/notifications/preferences"
    }
    
    // MARK: - Error Messages
    struct ErrorMessages {
        static let permissionDenied = "Notification permission denied. Please enable in Settings."
        static let tokenRegistrationFailed = "Failed to register device for notifications."
        static let deliveryFailed = "Failed to deliver notification."
        static let storageError = "Error saving notification data."
        static let networkError = "Network error while processing notification."
        static let invalidPayload = "Invalid notification payload received."
    }
    
    // MARK: - Success Messages
    struct SuccessMessages {
        static let permissionGranted = "Notifications enabled successfully!"
        static let tokenRegistered = "Device registered for notifications."
        static let notificationSent = "Notification sent successfully."
        static let preferencesUpdated = "Notification preferences updated."
    }
}

// MARK: - Notification Configuration
struct NotificationConfiguration {
    static let defaultSettings = NotificationSettings(
        isEnabled: true,
        soundEnabled: true,
        badgeEnabled: true,
        sifNotificationsEnabled: true,
        socialNotificationsEnabled: true,
        systemNotificationsEnabled: true,
        quietHoursEnabled: false,
        quietHoursStart: DateComponents(hour: 22, minute: 0), // 10:00 PM
        quietHoursEnd: DateComponents(hour: 8, minute: 0)     // 8:00 AM
    )
}

// MARK: - Notification Settings Model
struct NotificationSettings: Codable {
    var isEnabled: Bool
    var soundEnabled: Bool
    var badgeEnabled: Bool
    var sifNotificationsEnabled: Bool
    var socialNotificationsEnabled: Bool
    var systemNotificationsEnabled: Bool
    var quietHoursEnabled: Bool
    var quietHoursStart: DateComponents
    var quietHoursEnd: DateComponents
    
    var isInQuietHours: Bool {
        guard quietHoursEnabled else { return false }
        
        let now = Calendar.current.dateComponents([.hour, .minute], from: Date())
        let startMinutes = (quietHoursStart.hour ?? 0) * 60 + (quietHoursStart.minute ?? 0)
        let endMinutes = (quietHoursEnd.hour ?? 0) * 60 + (quietHoursEnd.minute ?? 0)
        let currentMinutes = (now.hour ?? 0) * 60 + (now.minute ?? 0)
        
        if startMinutes < endMinutes {
            // Same day quiet hours (e.g., 10 PM - 8 AM next day)
            return currentMinutes >= startMinutes || currentMinutes <= endMinutes
        } else {
            // Overnight quiet hours (e.g., 8 PM - 6 AM)
            return currentMinutes >= startMinutes && currentMinutes <= endMinutes
        }
    }
}