import Foundation
import UserNotifications

// MARK: - Notification settings view model
@MainActor
class NotificationSettingsViewModel: ObservableObject {
    
    // MARK: - Published properties
    @Published var pushNotificationsEnabled = true
    @Published var emailNotificationsEnabled = true
    @Published var inAppAlertsEnabled = true
    
    // SIF-specific notifications
    @Published var newSIFNotifications = true
    @Published var sifDeliveredNotifications = true
    @Published var sifOpenedNotifications = false
    @Published var templateUpdateNotifications = true
    
    // Social notifications
    @Published var friendRequestNotifications = true
    @Published var messageNotifications = true
    @Published var mentionNotifications = true
    
    // Marketing and updates
    @Published var marketingEmails = false
    @Published var productUpdates = true
    @Published var weeklyDigest = true
    
    // Frequency and timing
    @Published var notificationFrequency: NotificationFrequency = .normal
    @Published var quietHoursEnabled = false
    @Published var quietHoursStart = "22:00"
    @Published var quietHoursEnd = "08:00"
    
    // UI state
    @Published var systemNotificationStatus: UNAuthorizationStatus = .notDetermined
    @Published var showingSystemSettings = false
    @Published var isRequestingPermissions = false
    
    // MARK: - Private properties
    private let settingsService = SettingsService.shared
    
    // MARK: - Initialization
    init() {
        checkNotificationStatus()
    }
    
    // MARK: - Update settings
    func updateSettings(_ settings: NotificationSettings) {
        pushNotificationsEnabled = settings.pushNotificationsEnabled
        emailNotificationsEnabled = settings.emailNotificationsEnabled
        inAppAlertsEnabled = settings.inAppAlertsEnabled
        
        newSIFNotifications = settings.newSIFNotifications
        sifDeliveredNotifications = settings.sifDeliveredNotifications
        sifOpenedNotifications = settings.sifOpenedNotifications
        templateUpdateNotifications = settings.templateUpdateNotifications
        
        friendRequestNotifications = settings.friendRequestNotifications
        messageNotifications = settings.messageNotifications
        mentionNotifications = settings.mentionNotifications
        
        marketingEmails = settings.marketingEmails
        productUpdates = settings.productUpdates
        weeklyDigest = settings.weeklyDigest
        
        notificationFrequency = settings.notificationFrequency
        quietHoursEnabled = settings.quietHoursEnabled
        quietHoursStart = settings.quietHoursStart
        quietHoursEnd = settings.quietHoursEnd
    }
    
    // MARK: - Create settings object
    func createNotificationSettings() -> NotificationSettings {
        var settings = NotificationSettings()
        settings.pushNotificationsEnabled = pushNotificationsEnabled
        settings.emailNotificationsEnabled = emailNotificationsEnabled
        settings.inAppAlertsEnabled = inAppAlertsEnabled
        
        settings.newSIFNotifications = newSIFNotifications
        settings.sifDeliveredNotifications = sifDeliveredNotifications
        settings.sifOpenedNotifications = sifOpenedNotifications
        settings.templateUpdateNotifications = templateUpdateNotifications
        
        settings.friendRequestNotifications = friendRequestNotifications
        settings.messageNotifications = messageNotifications
        settings.mentionNotifications = mentionNotifications
        
        settings.marketingEmails = marketingEmails
        settings.productUpdates = productUpdates
        settings.weeklyDigest = weeklyDigest
        
        settings.notificationFrequency = notificationFrequency
        settings.quietHoursEnabled = quietHoursEnabled
        settings.quietHoursStart = quietHoursStart
        settings.quietHoursEnd = quietHoursEnd
        
        return settings
    }
    
    // MARK: - Save changes
    func saveChanges() async {
        let notificationSettings = createNotificationSettings()
        
        do {
            try await settingsService.updateNotificationSettings(notificationSettings)
        } catch {
            // Handle error - would be passed up to parent view model
        }
    }
    
    // MARK: - System notification permissions
    func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.systemNotificationStatus = settings.authorizationStatus
            }
        }
    }
    
    func requestNotificationPermissions() async {
        isRequestingPermissions = true
        
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            
            if granted {
                pushNotificationsEnabled = true
                await saveChanges()
            }
            
            checkNotificationStatus()
        } catch {
            // Handle permission request error
        }
        
        isRequestingPermissions = false
    }
    
    func openSystemSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
    
    // MARK: - Quick toggles
    func toggleAllNotifications() async {
        let newValue = !allNotificationsEnabled
        
        pushNotificationsEnabled = newValue
        emailNotificationsEnabled = newValue
        inAppAlertsEnabled = newValue
        
        newSIFNotifications = newValue
        sifDeliveredNotifications = newValue
        templateUpdateNotifications = newValue
        
        friendRequestNotifications = newValue
        messageNotifications = newValue
        mentionNotifications = newValue
        
        await saveChanges()
    }
    
    func setNotificationFrequency(_ frequency: NotificationFrequency) async {
        notificationFrequency = frequency
        await saveChanges()
    }
    
    // MARK: - Quiet hours management
    func toggleQuietHours() async {
        quietHoursEnabled.toggle()
        await saveChanges()
    }
    
    func updateQuietHours(start: String, end: String) async {
        guard isValidTimeFormat(start) && isValidTimeFormat(end) else { return }
        
        quietHoursStart = start
        quietHoursEnd = end
        await saveChanges()
    }
    
    // MARK: - Preset configurations
    func applyMinimalNotifications() async {
        pushNotificationsEnabled = true
        emailNotificationsEnabled = false
        inAppAlertsEnabled = true
        
        newSIFNotifications = true
        sifDeliveredNotifications = false
        sifOpenedNotifications = false
        templateUpdateNotifications = false
        
        friendRequestNotifications = true
        messageNotifications = true
        mentionNotifications = false
        
        marketingEmails = false
        productUpdates = false
        weeklyDigest = false
        
        notificationFrequency = .minimal
        
        await saveChanges()
    }
    
    func applyStandardNotifications() async {
        pushNotificationsEnabled = true
        emailNotificationsEnabled = true
        inAppAlertsEnabled = true
        
        newSIFNotifications = true
        sifDeliveredNotifications = true
        sifOpenedNotifications = false
        templateUpdateNotifications = true
        
        friendRequestNotifications = true
        messageNotifications = true
        mentionNotifications = true
        
        marketingEmails = false
        productUpdates = true
        weeklyDigest = true
        
        notificationFrequency = .normal
        
        await saveChanges()
    }
    
    func applyAllNotifications() async {
        pushNotificationsEnabled = true
        emailNotificationsEnabled = true
        inAppAlertsEnabled = true
        
        newSIFNotifications = true
        sifDeliveredNotifications = true
        sifOpenedNotifications = true
        templateUpdateNotifications = true
        
        friendRequestNotifications = true
        messageNotifications = true
        mentionNotifications = true
        
        marketingEmails = true
        productUpdates = true
        weeklyDigest = true
        
        notificationFrequency = .immediate
        
        await saveChanges()
    }
    
    // MARK: - Helper methods
    private func isValidTimeFormat(_ time: String) -> Bool {
        let timeRegex = "^([01]?[0-9]|2[0-3]):[0-5][0-9]$"
        let timeTest = NSPredicate(format: "SELF MATCHES %@", timeRegex)
        return timeTest.evaluate(with: time)
    }
    
    // MARK: - Computed properties
    var allNotificationsEnabled: Bool {
        pushNotificationsEnabled && emailNotificationsEnabled && inAppAlertsEnabled &&
        newSIFNotifications && sifDeliveredNotifications && templateUpdateNotifications &&
        friendRequestNotifications && messageNotifications && mentionNotifications
    }
    
    var hasSystemPermissions: Bool {
        systemNotificationStatus == .authorized
    }
    
    var needsSystemPermissions: Bool {
        systemNotificationStatus == .notDetermined || systemNotificationStatus == .denied
    }
    
    var enabledNotificationsCount: Int {
        var count = 0
        if newSIFNotifications { count += 1 }
        if sifDeliveredNotifications { count += 1 }
        if sifOpenedNotifications { count += 1 }
        if templateUpdateNotifications { count += 1 }
        if friendRequestNotifications { count += 1 }
        if messageNotifications { count += 1 }
        if mentionNotifications { count += 1 }
        return count
    }
    
    var notificationSummary: String {
        if !pushNotificationsEnabled && !emailNotificationsEnabled {
            return "All notifications disabled"
        } else if allNotificationsEnabled {
            return "All notifications enabled"
        } else {
            return "\(enabledNotificationsCount) notification types enabled"
        }
    }
    
    var quietHoursSummary: String {
        if quietHoursEnabled {
            return "Active from \(quietHoursStart) to \(quietHoursEnd)"
        } else {
            return "Disabled"
        }
    }
}