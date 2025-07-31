import Foundation

// This struct defines the data we will store for each user
// in our Firestore database.
struct User: Codable, Identifiable {
    let id: String
    let uid: String
    let name: String
    let email: String
    var displayName: String?
    var bio: String?
    var profileImageUrl: String?
    var createdAt: Date?
    var updatedAt: Date?
    
    // User Statistics
    var sifsCreated: Int
    var sifsSent: Int
    var sifsReceived: Int
    var joinedDate: Date?
    
    // Privacy Settings
    var privacySettings: PrivacySettings
    
    // Notification Settings  
    var notificationSettings: NotificationSettings
    
    init(uid: String, name: String, email: String) {
        self.id = uid
        self.uid = uid
        self.name = name
        self.email = email
        self.displayName = name
        self.bio = nil
        self.profileImageUrl = nil
        self.createdAt = Date()
        self.updatedAt = Date()
        self.sifsCreated = 0
        self.sifsSent = 0
        self.sifsReceived = 0
        self.joinedDate = Date()
        self.privacySettings = PrivacySettings()
        self.notificationSettings = NotificationSettings()
    }
}

// MARK: - Privacy Settings
struct PrivacySettings: Codable {
    var profileVisibility: ProfileVisibility
    var allowsMessagesFromStrangers: Bool
    var showOnlineStatus: Bool
    var showLastSeen: Bool
    var allowProfileImageDownload: Bool
    
    init() {
        self.profileVisibility = .everyone
        self.allowsMessagesFromStrangers = true
        self.showOnlineStatus = true
        self.showLastSeen = true
        self.allowProfileImageDownload = true
    }
}

enum ProfileVisibility: String, CaseIterable, Codable {
    case everyone = "everyone"
    case friendsOnly = "friends_only"
    case nobody = "nobody"
    
    var displayName: String {
        switch self {
        case .everyone: return "Everyone"
        case .friendsOnly: return "Friends Only"
        case .nobody: return "Nobody"
        }
    }
}

// MARK: - Notification Settings
struct NotificationSettings: Codable {
    var pushNotificationsEnabled: Bool
    var emailNotificationsEnabled: Bool
    var newSIFNotifications: Bool
    var scheduledSIFReminders: Bool
    var friendRequestNotifications: Bool
    var marketingNotifications: Bool
    var soundEnabled: Bool
    var vibrationEnabled: Bool
    var quietHoursEnabled: Bool
    var quietHoursStart: String // Format: "22:00"
    var quietHoursEnd: String   // Format: "08:00"
    
    init() {
        self.pushNotificationsEnabled = true
        self.emailNotificationsEnabled = true
        self.newSIFNotifications = true
        self.scheduledSIFReminders = true
        self.friendRequestNotifications = true
        self.marketingNotifications = false
        self.soundEnabled = true
        self.vibrationEnabled = true
        self.quietHoursEnabled = false
        self.quietHoursStart = "22:00"
        self.quietHoursEnd = "08:00"
    }
}
