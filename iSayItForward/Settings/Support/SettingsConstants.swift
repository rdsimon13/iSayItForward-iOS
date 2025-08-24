import Foundation

// MARK: - Settings constants
struct SettingsConstants {
    
    // MARK: - Firestore collections
    static let userSettingsCollection = "userSettings"
    static let userProfilesCollection = "userProfiles"
    
    // MARK: - UserDefaults keys
    static let settingsVersionKey = "settings_version"
    static let lastSyncDateKey = "last_settings_sync_date"
    static let offlineSettingsKey = "offline_settings"
    static let hasCompletedOnboardingKey = "has_completed_onboarding"
    
    // MARK: - Settings version
    static let currentSettingsVersion = 1
    
    // MARK: - Validation limits
    static let maxBioLength = 500
    static let maxDisplayNameLength = 50
    static let maxSkillsCount = 10
    static let maxExpertiseCount = 5
    static let maxBlockedUsersCount = 1000
    
    // MARK: - Default values
    static let defaultQuietHoursStart = "22:00"
    static let defaultQuietHoursEnd = "08:00"
    static let defaultLanguage = "en"
    
    // MARK: - Cache settings
    static let settingsCacheExpirationMinutes = 30
    static let maxRetryAttempts = 3
    static let retryDelaySeconds = 2.0
    
    // MARK: - Feature flags
    static let enableSettingsSync = true
    static let enableOfflineMode = true
    static let enableAdvancedPrivacy = true
    static let enableAccessibilityFeatures = true
}