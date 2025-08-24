import Foundation
import Combine
import SwiftUI

// MARK: - Notification Settings ViewModel
@MainActor
class NotificationSettingsViewModel: ObservableObject {
    @Published var settings: NotificationSettings
    @Published var isPermissionGranted: Bool = false
    @Published var deviceToken: String?
    @Published var isLoading: Bool = false
    @Published var showingPermissionAlert: Bool = false
    @Published var showingQuietHoursSheet: Bool = false
    
    private let notificationService = NotificationService.shared
    private let userDefaults = UserDefaults.standard
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.settings = loadSettings()
        setupSubscriptions()
    }
    
    // MARK: - Setup
    private func setupSubscriptions() {
        notificationService.$isPermissionGranted
            .receive(on: DispatchQueue.main)
            .assign(to: \.isPermissionGranted, on: self)
            .store(in: &cancellables)
        
        notificationService.$deviceToken
            .receive(on: DispatchQueue.main)
            .assign(to: \.deviceToken, on: self)
            .store(in: &cancellables)
        
        // Save settings whenever they change
        $settings
            .dropFirst() // Skip initial value
            .sink { [weak self] settings in
                self?.saveSettings(settings)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Settings Management
    func toggleNotifications() async {
        if settings.isEnabled {
            // Disabling notifications
            settings.isEnabled = false
        } else {
            // Enabling notifications - request permission first
            await requestPermission()
        }
    }
    
    func toggleSound() {
        settings.soundEnabled.toggle()
    }
    
    func toggleBadge() {
        settings.badgeEnabled.toggle()
    }
    
    func toggleSIFNotifications() {
        settings.sifNotificationsEnabled.toggle()
    }
    
    func toggleSocialNotifications() {
        settings.socialNotificationsEnabled.toggle()
    }
    
    func toggleSystemNotifications() {
        settings.systemNotificationsEnabled.toggle()
    }
    
    func toggleQuietHours() {
        settings.quietHoursEnabled.toggle()
    }
    
    func updateQuietHoursStart(_ time: DateComponents) {
        settings.quietHoursStart = time
    }
    
    func updateQuietHoursEnd(_ time: DateComponents) {
        settings.quietHoursEnd = time
    }
    
    // MARK: - Permission Management
    func requestPermission() async {
        isLoading = true
        
        await notificationService.requestPermissions()
        
        if isPermissionGranted {
            settings.isEnabled = true
        } else {
            showingPermissionAlert = true
        }
        
        isLoading = false
    }
    
    func openSystemSettings() {
        NotificationUtilities.openNotificationSettings()
    }
    
    // MARK: - Quiet Hours
    var quietHoursStartTime: Date {
        let components = settings.quietHoursStart
        let calendar = Calendar.current
        return calendar.date(from: components) ?? Date()
    }
    
    var quietHoursEndTime: Date {
        let components = settings.quietHoursEnd
        let calendar = Calendar.current
        return calendar.date(from: components) ?? Date()
    }
    
    func updateQuietHoursStart(time: Date) {
        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        settings.quietHoursStart = components
    }
    
    func updateQuietHoursEnd(time: Date) {
        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        settings.quietHoursEnd = components
    }
    
    var quietHoursDescription: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        let startTime = formatter.string(from: quietHoursStartTime)
        let endTime = formatter.string(from: quietHoursEndTime)
        
        return "\(startTime) - \(endTime)"
    }
    
    var isCurrentlyInQuietHours: Bool {
        return settings.isInQuietHours
    }
    
    // MARK: - Notification Categories Management
    func isNotificationTypeEnabled(_ type: NotificationType) -> Bool {
        switch type.category {
        case .sif:
            return settings.sifNotificationsEnabled
        case .social:
            return settings.socialNotificationsEnabled
        case .system:
            return settings.systemNotificationsEnabled
        case .template:
            return settings.sifNotificationsEnabled // Templates are part of SIF notifications
        case .achievement:
            return settings.systemNotificationsEnabled // Achievements are part of system notifications
        }
    }
    
    func toggleNotificationType(_ type: NotificationType) {
        switch type.category {
        case .sif, .template:
            settings.sifNotificationsEnabled.toggle()
        case .social:
            settings.socialNotificationsEnabled.toggle()
        case .system, .achievement:
            settings.systemNotificationsEnabled.toggle()
        }
    }
    
    // MARK: - Storage
    private func loadSettings() -> NotificationSettings {
        guard let data = userDefaults.data(forKey: "notification_settings"),
              let settings = try? JSONDecoder().decode(NotificationSettings.self, from: data) else {
            return NotificationConfiguration.defaultSettings
        }
        return settings
    }
    
    private func saveSettings(_ settings: NotificationSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        userDefaults.set(data, forKey: "notification_settings")
    }
    
    // MARK: - Testing
    func sendTestNotification() async {
        guard let currentUser = AuthenticationService.shared.currentAppUser else { return }
        
        let testNotification = Notification(
            title: "Test Notification",
            body: "This is a test notification to verify your settings.",
            type: .systemUpdate,
            recipientUID: currentUser.uid,
            priority: .normal
        )
        
        notificationService.addNotification(testNotification)
    }
    
    // MARK: - Reset
    func resetToDefaults() {
        settings = NotificationConfiguration.defaultSettings
    }
    
    // MARK: - Computed Properties
    var hasValidSettings: Bool {
        return isPermissionGranted && settings.isEnabled
    }
    
    var enabledNotificationTypesCount: Int {
        var count = 0
        if settings.sifNotificationsEnabled { count += 1 }
        if settings.socialNotificationsEnabled { count += 1 }
        if settings.systemNotificationsEnabled { count += 1 }
        return count
    }
    
    var notificationStatusText: String {
        if !isPermissionGranted {
            return "Permission required"
        } else if !settings.isEnabled {
            return "Disabled"
        } else if isCurrentlyInQuietHours {
            return "Quiet hours active"
        } else {
            return "Active"
        }
    }
    
    var deviceTokenShort: String? {
        guard let token = deviceToken else { return nil }
        if token.count > 16 {
            return String(token.prefix(8)) + "..." + String(token.suffix(8))
        }
        return token
    }
}