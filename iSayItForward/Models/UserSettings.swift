import Foundation

// MARK: - Core settings model that aggregates all user preferences
struct UserSettings: Codable {
    let uid: String
    var profileSettings: ProfileSettings
    var privacySettings: PrivacySettings
    var notificationSettings: NotificationSettings
    var appearanceSettings: AppearanceSettings
    var lastUpdated: Date
    var version: Int
    
    init(uid: String) {
        self.uid = uid
        self.profileSettings = ProfileSettings()
        self.privacySettings = PrivacySettings()
        self.notificationSettings = NotificationSettings()
        self.appearanceSettings = AppearanceSettings()
        self.lastUpdated = Date()
        self.version = 1
    }
}