import Foundation

// MARK: - Notification Constants
struct NotificationConstants {
    
    // MARK: - Firebase Collections
    struct Collections {
        static let notifications = "notifications"
        static let notificationPreferences = "notification_preferences"
        static let notificationTokens = "notification_tokens"
    }
    
    // MARK: - UserDefaults Keys
    struct UserDefaults {
        static let badgeCount = "notification_badge_count"
        static let lastSyncDate = "notification_last_sync_date"
        static let deviceToken = "notification_device_token"
        static let pendingNotifications = "notification_pending_notifications"
    }
    
    // MARK: - Push Notification Configuration
    struct PushNotification {
        static let maxRetryAttempts = 3
        static let retryDelay: TimeInterval = 2.0
        static let tokenRefreshInterval: TimeInterval = 86400 // 24 hours
        static let maxNotificationsPerDay = 100
        static let silentNotificationIdentifier = "silent-notification"
    }
    
    // MARK: - Badge Configuration
    struct Badge {
        static let maxBadgeCount = 99
        static let updateInterval: TimeInterval = 30.0
        static let animationDuration: TimeInterval = 0.3
    }
    
    // MARK: - Notification Center Configuration
    struct NotificationCenter {
        static let maxNotificationsToShow = 50
        static let autoRefreshInterval: TimeInterval = 60.0
        static let groupingTimeThreshold: TimeInterval = 3600 // 1 hour
        static let maxGroupSize = 5
    }
    
    // MARK: - Scheduling Configuration
    struct Scheduling {
        static let maxScheduledNotifications = 64 // iOS limit
        static let defaultReminderTime: TimeInterval = 3600 // 1 hour
        static let maxScheduleAheadTime: TimeInterval = 2592000 // 30 days
    }
    
    // MARK: - Error Messages
    struct ErrorMessages {
        static let permissionDenied = "Notification permissions are required to receive updates."
        static let registrationFailed = "Failed to register for notifications. Please try again."
        static let tokenRegistrationFailed = "Failed to register device token."
        static let schedulingFailed = "Failed to schedule notification."
        static let networkError = "Network error occurred while syncing notifications."
        static let unknownError = "An unknown error occurred."
    }
    
    // MARK: - Default Sounds
    struct Sounds {
        static let defaultSound = "default"
        static let messageSound = "message.caf"
        static let milestoneSound = "milestone.caf"
        static let mentionSound = "mention.caf"
        static let reminderSound = "reminder.caf"
        static let systemSound = "system.caf"
    }
    
    // MARK: - Action Identifiers
    struct ActionIdentifiers {
        static let reply = "REPLY_ACTION"
        static let view = "VIEW_ACTION"
        static let dismiss = "DISMISS_ACTION"
        static let markAsRead = "MARK_AS_READ_ACTION"
        static let delete = "DELETE_ACTION"
        static let share = "SHARE_ACTION"
        static let archive = "ARCHIVE_ACTION"
        static let openSIF = "OPEN_SIF_ACTION"
        static let openProfile = "OPEN_PROFILE_ACTION"
        static let scheduleReminder = "SCHEDULE_REMINDER_ACTION"
    }
    
    // MARK: - Category Identifiers
    struct CategoryIdentifiers {
        static let messageResponse = "MESSAGE_RESPONSE"
        static let impactMilestone = "IMPACT_MILESTONE"
        static let mention = "MENTION"
        static let systemNotification = "SYSTEM_NOTIFICATION"
        static let communityUpdate = "COMMUNITY_UPDATE"
        static let sifDelivered = "SIF_DELIVERED"
        static let sifReceived = "SIF_RECEIVED"
        static let reminderScheduled = "REMINDER_SCHEDULED"
        static let accountUpdate = "ACCOUNT_UPDATE"
        static let newFeature = "NEW_FEATURE"
    }
    
    // MARK: - Deep Link URLs
    struct DeepLinks {
        static let scheme = "isayitforward"
        static let host = "app"
        
        static let notificationCenter = "\(scheme)://\(host)/notifications"
        static let sifDetail = "\(scheme)://\(host)/sif"
        static let profile = "\(scheme)://\(host)/profile"
        static let settings = "\(scheme)://\(host)/settings"
        static let home = "\(scheme)://\(host)/home"
    }
    
    // MARK: - Notification Keys (for payload parsing)
    struct PayloadKeys {
        static let notificationId = "notification_id"
        static let notificationType = "notification_type"
        static let userId = "user_id"
        static let sifId = "sif_id"
        static let relatedUserId = "related_user_id"
        static let deepLinkURL = "deep_link_url"
        static let customData = "custom_data"
        static let groupId = "group_id"
        static let category = "category"
        static let priority = "priority"
        static let isSilent = "silent"
        static let shouldShowBadge = "badge"
    }
}