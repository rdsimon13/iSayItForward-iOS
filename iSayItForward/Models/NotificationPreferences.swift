import Foundation

// MARK: - Notification Preferences Model
struct NotificationPreferences: Codable {
    let userId: String
    var isEnabled: Bool
    var soundEnabled: Bool
    var badgeEnabled: Bool
    var bannerEnabled: Bool
    var lockScreenEnabled: Bool
    var notificationCenterEnabled: Bool
    
    // Category preferences
    var categoryPreferences: [NotificationCategory: CategoryPreference]
    
    // Type-specific preferences
    var typePreferences: [NotificationType: TypePreference]
    
    // Quiet hours
    var quietHoursEnabled: Bool
    var quietHoursStart: Date
    var quietHoursEnd: Date
    
    // Frequency settings
    var digestEnabled: Bool
    var digestFrequency: DigestFrequency
    var maxNotificationsPerHour: Int
    
    init(userId: String) {
        self.userId = userId
        self.isEnabled = true
        self.soundEnabled = true
        self.badgeEnabled = true
        self.bannerEnabled = true
        self.lockScreenEnabled = true
        self.notificationCenterEnabled = true
        
        // Initialize category preferences with default values
        self.categoryPreferences = [:]
        for category in NotificationCategory.allCases {
            self.categoryPreferences[category] = CategoryPreference()
        }
        
        // Initialize type preferences with default values
        self.typePreferences = [:]
        for type in NotificationType.allCases {
            self.typePreferences[type] = TypePreference()
        }
        
        self.quietHoursEnabled = false
        
        // Default quiet hours: 10 PM to 8 AM
        let calendar = Calendar.current
        self.quietHoursStart = calendar.date(bySettingHour: 22, minute: 0, second: 0, of: Date()) ?? Date()
        self.quietHoursEnd = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
        
        self.digestEnabled = false
        self.digestFrequency = .daily
        self.maxNotificationsPerHour = 10
    }
}

// MARK: - Category Preference
struct CategoryPreference: Codable {
    var isEnabled: Bool
    var soundEnabled: Bool
    var badgeEnabled: Bool
    var priority: NotificationPriority
    
    init(isEnabled: Bool = true, soundEnabled: Bool = true, badgeEnabled: Bool = true, priority: NotificationPriority = .normal) {
        self.isEnabled = isEnabled
        self.soundEnabled = soundEnabled
        self.badgeEnabled = badgeEnabled
        self.priority = priority
    }
}

// MARK: - Type Preference
struct TypePreference: Codable {
    var isEnabled: Bool
    var soundEnabled: Bool
    var badgeEnabled: Bool
    var customSound: String?
    var customActions: [NotificationAction]?
    
    init(isEnabled: Bool = true, soundEnabled: Bool = true, badgeEnabled: Bool = true) {
        self.isEnabled = isEnabled
        self.soundEnabled = soundEnabled
        self.badgeEnabled = badgeEnabled
        self.customSound = nil
        self.customActions = nil
    }
}

// MARK: - Digest Frequency
enum DigestFrequency: String, Codable, CaseIterable {
    case hourly = "hourly"
    case daily = "daily"
    case weekly = "weekly"
    case never = "never"
    
    var displayName: String {
        switch self {
        case .hourly: return "Hourly"
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .never: return "Never"
        }
    }
    
    var interval: TimeInterval? {
        switch self {
        case .hourly: return 3600 // 1 hour
        case .daily: return 86400 // 24 hours
        case .weekly: return 604800 // 7 days
        case .never: return nil
        }
    }
}

// MARK: - Convenience Extensions
extension NotificationPreferences {
    func isNotificationAllowed(for type: NotificationType) -> Bool {
        guard isEnabled else { return false }
        
        // Check category preference
        let category = type.category
        if let categoryPref = categoryPreferences[category], !categoryPref.isEnabled {
            return false
        }
        
        // Check type preference
        if let typePref = typePreferences[type], !typePref.isEnabled {
            return false
        }
        
        return true
    }
    
    func shouldPlaySound(for type: NotificationType) -> Bool {
        guard soundEnabled else { return false }
        
        // Check category preference
        let category = type.category
        if let categoryPref = categoryPreferences[category], !categoryPref.soundEnabled {
            return false
        }
        
        // Check type preference
        if let typePref = typePreferences[type], !typePref.soundEnabled {
            return false
        }
        
        return true
    }
    
    func shouldShowBadge(for type: NotificationType) -> Bool {
        guard badgeEnabled else { return false }
        
        // Check category preference
        let category = type.category
        if let categoryPref = categoryPreferences[category], !categoryPref.badgeEnabled {
            return false
        }
        
        // Check type preference
        if let typePref = typePreferences[type], !typePref.badgeEnabled {
            return false
        }
        
        return true
    }
    
    func isInQuietHours() -> Bool {
        guard quietHoursEnabled else { return false }
        
        let now = Date()
        let calendar = Calendar.current
        
        let currentTime = calendar.dateComponents([.hour, .minute], from: now)
        let startTime = calendar.dateComponents([.hour, .minute], from: quietHoursStart)
        let endTime = calendar.dateComponents([.hour, .minute], from: quietHoursEnd)
        
        guard let currentHour = currentTime.hour,
              let currentMinute = currentTime.minute,
              let startHour = startTime.hour,
              let startMinute = startTime.minute,
              let endHour = endTime.hour,
              let endMinute = endTime.minute else {
            return false
        }
        
        let currentMinutes = currentHour * 60 + currentMinute
        let startMinutes = startHour * 60 + startMinute
        let endMinutes = endHour * 60 + endMinute
        
        if startMinutes <= endMinutes {
            // Same day quiet hours
            return currentMinutes >= startMinutes && currentMinutes <= endMinutes
        } else {
            // Overnight quiet hours
            return currentMinutes >= startMinutes || currentMinutes <= endMinutes
        }
    }
}