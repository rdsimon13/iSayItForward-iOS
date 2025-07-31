import Foundation

// MARK: - Default settings provider
struct SettingsDefaults {
    
    // MARK: - Create default settings for a user
    static func createDefaultSettings(for uid: String) -> UserSettings {
        return UserSettings(uid: uid)
    }
    
    // MARK: - Default profile settings
    static func defaultProfileSettings() -> ProfileSettings {
        return ProfileSettings()
    }
    
    // MARK: - Default privacy settings
    static func defaultPrivacySettings() -> PrivacySettings {
        return PrivacySettings()
    }
    
    // MARK: - Default notification settings
    static func defaultNotificationSettings() -> NotificationSettings {
        return NotificationSettings()
    }
    
    // MARK: - Default appearance settings
    static func defaultAppearanceSettings() -> AppearanceSettings {
        return AppearanceSettings()
    }
    
    // MARK: - Safe defaults for new users
    static func safeDefaultSettings(for uid: String) -> UserSettings {
        var settings = createDefaultSettings(for: uid)
        
        // More conservative privacy defaults for new users
        settings.privacySettings.profileVisibility = .friendsOnly
        settings.privacySettings.allowSIFFromStrangers = false
        settings.privacySettings.allowDataCollection = false
        settings.privacySettings.allowAnalytics = false
        settings.privacySettings.allowLocationSharing = false
        settings.privacySettings.allowContactSync = false
        
        // Conservative notification defaults
        settings.notificationSettings.marketingEmails = false
        settings.notificationSettings.weeklyDigest = false
        settings.notificationSettings.sifOpenedNotifications = false
        
        return settings
    }
    
    // MARK: - Restore factory defaults
    static func factoryReset(preservingUID uid: String) -> UserSettings {
        return createDefaultSettings(for: uid)
    }
}