import Foundation
import UserNotifications

// MARK: - Notification Permissions Manager
class NotificationPermissions: ObservableObject {
    
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var isPermissionGranted: Bool = false
    
    static let shared = NotificationPermissions()
    
    private init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Permission Checking
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus
                self.isPermissionGranted = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Permission Requests
    func requestPermissions(completion: @escaping (Bool, Error?) -> Void) {
        let options: UNAuthorizationOptions = [.alert, .badge, .sound, .provisional]
        
        UNUserNotificationCenter.current().requestAuthorization(options: options) { granted, error in
            DispatchQueue.main.async {
                self.authorizationStatus = granted ? .authorized : .denied
                self.isPermissionGranted = granted
                completion(granted, error)
            }
        }
    }
    
    func requestProvisionalPermissions(completion: @escaping (Bool, Error?) -> Void) {
        let options: UNAuthorizationOptions = [.provisional, .badge, .sound]
        
        UNUserNotificationCenter.current().requestAuthorization(options: options) { granted, error in
            DispatchQueue.main.async {
                self.authorizationStatus = granted ? .provisional : .denied
                self.isPermissionGranted = granted
                completion(granted, error)
            }
        }
    }
    
    // MARK: - Permission Status Helpers
    var canSendNotifications: Bool {
        return authorizationStatus == .authorized || authorizationStatus == .provisional
    }
    
    var shouldRequestPermissions: Bool {
        return authorizationStatus == .notDetermined
    }
    
    var isExplicitlyDenied: Bool {
        return authorizationStatus == .denied
    }
    
    var statusDescription: String {
        switch authorizationStatus {
        case .notDetermined:
            return "Not requested"
        case .denied:
            return "Denied"
        case .authorized:
            return "Authorized"
        case .provisional:
            return "Provisional"
        case .ephemeral:
            return "Ephemeral"
        @unknown default:
            return "Unknown"
        }
    }
    
    // MARK: - Settings Navigation
    func openNotificationSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL)
        }
    }
    
    // MARK: - Notification Settings Details
    func getDetailedSettings(completion: @escaping (UNNotificationSettings) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings)
            }
        }
    }
    
    func getPermissionDetails(completion: @escaping (PermissionDetails) -> Void) {
        getDetailedSettings { settings in
            let details = PermissionDetails(
                authorizationStatus: settings.authorizationStatus,
                alertSetting: settings.alertSetting,
                badgeSetting: settings.badgeSetting,
                soundSetting: settings.soundSetting,
                lockScreenSetting: settings.lockScreenSetting,
                notificationCenterSetting: settings.notificationCenterSetting,
                carPlaySetting: settings.carPlaySetting,
                criticalAlertSetting: settings.criticalAlertSetting,
                announcementSetting: settings.announcementSetting,
                scheduledDeliverySetting: settings.scheduledDeliverySetting
            )
            completion(details)
        }
    }
}

// MARK: - Permission Details Model
struct PermissionDetails {
    let authorizationStatus: UNAuthorizationStatus
    let alertSetting: UNNotificationSetting
    let badgeSetting: UNNotificationSetting
    let soundSetting: UNNotificationSetting
    let lockScreenSetting: UNNotificationSetting
    let notificationCenterSetting: UNNotificationSetting
    let carPlaySetting: UNNotificationSetting
    let criticalAlertSetting: UNNotificationSetting
    let announcementSetting: UNNotificationSetting
    let scheduledDeliverySetting: UNNotificationSetting
    
    var isFullyEnabled: Bool {
        return authorizationStatus == .authorized &&
               alertSetting == .enabled &&
               badgeSetting == .enabled &&
               soundSetting == .enabled
    }
    
    var hasBasicPermissions: Bool {
        return authorizationStatus == .authorized || authorizationStatus == .provisional
    }
    
    var canShowAlerts: Bool {
        return alertSetting == .enabled
    }
    
    var canShowBadges: Bool {
        return badgeSetting == .enabled
    }
    
    var canPlaySounds: Bool {
        return soundSetting == .enabled
    }
    
    var canShowOnLockScreen: Bool {
        return lockScreenSetting == .enabled
    }
    
    var canShowInNotificationCenter: Bool {
        return notificationCenterSetting == .enabled
    }
    
    var summary: String {
        var components: [String] = []
        
        if canShowAlerts { components.append("Alerts") }
        if canShowBadges { components.append("Badges") }
        if canPlaySounds { components.append("Sounds") }
        if canShowOnLockScreen { components.append("Lock Screen") }
        if canShowInNotificationCenter { components.append("Notification Center") }
        
        if components.isEmpty {
            return "No permissions enabled"
        } else {
            return components.joined(separator: ", ")
        }
    }
}

// MARK: - Error Types
enum NotificationPermissionError: LocalizedError {
    case permissionDenied
    case permissionNotDetermined
    case systemError(Error)
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Notification permissions have been denied. Please enable them in Settings."
        case .permissionNotDetermined:
            return "Notification permissions have not been requested."
        case .systemError(let error):
            return "System error: \(error.localizedDescription)"
        }
    }
}