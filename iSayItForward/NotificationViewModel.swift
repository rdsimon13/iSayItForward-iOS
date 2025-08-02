import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

/// Settings for notification preferences and behavior
struct NotificationSettings: Codable, Equatable {
    /// Whether notifications are enabled globally
    var isEnabled: Bool
    
    /// Notification preferences by type
    var typePreferences: [NotificationType: Bool]
    
    /// Minimum priority level to show notifications
    var minimumPriority: NotificationPriority
    
    /// Whether to show notifications on lock screen
    var showOnLockScreen: Bool
    
    /// Whether to play sound for notifications
    var playSound: Bool
    
    /// Whether to show badge count
    var showBadge: Bool
    
    /// Quiet hours start time (24-hour format)
    var quietHoursStart: Int?
    
    /// Quiet hours end time (24-hour format)
    var quietHoursEnd: Int?
    
    /// Default initializer with sensible defaults
    init(
        isEnabled: Bool = true,
        typePreferences: [NotificationType: Bool] = Dictionary(uniqueKeysWithValues: NotificationType.allCases.map { ($0, true) }),
        minimumPriority: NotificationPriority = .low,
        showOnLockScreen: Bool = true,
        playSound: Bool = true,
        showBadge: Bool = true,
        quietHoursStart: Int? = nil,
        quietHoursEnd: Int? = nil
    ) {
        self.isEnabled = isEnabled
        self.typePreferences = typePreferences
        self.minimumPriority = minimumPriority
        self.showOnLockScreen = showOnLockScreen
        self.playSound = playSound
        self.showBadge = showBadge
        self.quietHoursStart = quietHoursStart
        self.quietHoursEnd = quietHoursEnd
    }
    
    /// Check if a specific notification type is enabled
    func isTypeEnabled(_ type: NotificationType) -> Bool {
        return isEnabled && (typePreferences[type] ?? true)
    }
    
    /// Check if notifications should be shown during quiet hours
    var isInQuietHours: Bool {
        guard let start = quietHoursStart, let end = quietHoursEnd else { return false }
        
        let calendar = Calendar.current
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)
        
        if start <= end {
            // Normal case: e.g., 22:00 to 06:00 next day
            return currentHour >= start && currentHour < end
        } else {
            // Crosses midnight: e.g., 22:00 to 06:00 next day
            return currentHour >= start || currentHour < end
        }
    }
}

/// View model for managing notifications and notification settings
@MainActor
class NotificationSettingsViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// Current notification settings
    @Published var settings: NotificationSettings = NotificationSettings()
    
    /// List of all notifications
    @Published var notifications: [NotificationItem] = []
    
    /// Whether data is currently loading
    @Published var isLoading: Bool = false
    
    /// Error message if any operation fails
    @Published var errorMessage: String? = nil
    
    /// Whether to show error alert
    @Published var showingError: Bool = false
    
    // MARK: - Private Properties
    
    private let db = Firestore.firestore()
    private var settingsListener: ListenerRegistration?
    private var notificationsListener: ListenerRegistration?
    
    // MARK: - Computed Properties
    
    /// Unread notification count
    var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }
    
    /// High priority unread notifications
    var highPriorityUnread: [NotificationItem] {
        notifications.filter { !$0.isRead && $0.priority.rawValue >= NotificationPriority.high.rawValue }
    }
    
    /// Notifications grouped by type
    var notificationsByType: [NotificationType: [NotificationItem]] {
        Dictionary(grouping: notifications) { $0.type }
    }
    
    /// Recent notifications (last 24 hours)
    var recentNotifications: [NotificationItem] {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        return notifications.filter { $0.createdDate > yesterday }
    }
    
    // MARK: - Initialization
    
    init() {
        loadData()
    }
    
    deinit {
        settingsListener?.remove()
        notificationsListener?.remove()
    }
    
    // MARK: - Public Methods
    
    /// Load notification settings and notifications
    func loadData() {
        guard let uid = Auth.auth().currentUser?.uid else {
            self.errorMessage = "User not authenticated"
            self.showingError = true
            return
        }
        
        isLoading = true
        loadSettings(for: uid)
        loadNotifications(for: uid)
    }
    
    /// Update notification settings
    func updateSettings(_ newSettings: NotificationSettings) {
        guard let uid = Auth.auth().currentUser?.uid else {
            handleError("User not authenticated")
            return
        }
        
        isLoading = true
        
        do {
            try db.collection("users").document(uid).collection("settings").document("notifications").setData(from: newSettings) { [weak self] error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    if let error = error {
                        self?.handleError("Failed to update settings: \(error.localizedDescription)")
                    } else {
                        self?.settings = newSettings
                    }
                }
            }
        } catch {
            isLoading = false
            handleError("Failed to encode settings: \(error.localizedDescription)")
        }
    }
    
    /// Mark a notification as read
    func markAsRead(_ notification: NotificationItem) {
        guard let uid = Auth.auth().currentUser?.uid else {
            handleError("User not authenticated")
            return
        }
        
        var updatedNotification = notification
        updatedNotification.isRead = true
        
        do {
            try db.collection("users").document(uid).collection("notifications").document(notification.id.uuidString).setData(from: updatedNotification) { [weak self] error in
                if let error = error {
                    DispatchQueue.main.async {
                        self?.handleError("Failed to mark notification as read: \(error.localizedDescription)")
                    }
                }
            }
        } catch {
            handleError("Failed to encode notification: \(error.localizedDescription)")
        }
    }
    
    /// Mark all notifications as read
    func markAllAsRead() {
        let unreadNotifications = notifications.filter { !$0.isRead }
        for notification in unreadNotifications {
            markAsRead(notification)
        }
    }
    
    /// Delete a notification
    func deleteNotification(_ notification: NotificationItem) {
        guard let uid = Auth.auth().currentUser?.uid else {
            handleError("User not authenticated")
            return
        }
        
        db.collection("users").document(uid).collection("notifications").document(notification.id.uuidString).delete { [weak self] error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.handleError("Failed to delete notification: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Create a new notification
    func createNotification(
        type: NotificationType,
        title: String,
        message: String,
        priority: NotificationPriority? = nil,
        scheduledDate: Date? = nil,
        sifId: String? = nil,
        metadata: [String: String]? = nil
    ) {
        guard let uid = Auth.auth().currentUser?.uid else {
            handleError("User not authenticated")
            return
        }
        
        let notification = NotificationItem(
            type: type,
            priority: priority,
            title: title,
            message: message,
            scheduledDate: scheduledDate,
            sifId: sifId,
            metadata: metadata
        )
        
        do {
            try db.collection("users").document(uid).collection("notifications").document(notification.id.uuidString).setData(from: notification) { [weak self] error in
                if let error = error {
                    DispatchQueue.main.async {
                        self?.handleError("Failed to create notification: \(error.localizedDescription)")
                    }
                }
            }
        } catch {
            handleError("Failed to encode notification: \(error.localizedDescription)")
        }
    }
    
    /// Perform an action on a notification
    func performAction(_ action: NotificationAction, on notification: NotificationItem) {
        switch action {
        case .view:
            // This would typically navigate to the relevant view
            markAsRead(notification)
        case .dismiss:
            markAsRead(notification)
        case .delete:
            deleteNotification(notification)
        case .markAsRead:
            markAsRead(notification)
        case .snooze:
            // Implement snooze logic (create a new scheduled notification)
            snoozeNotification(notification)
        case .reply, .schedule, .share:
            // These would typically open relevant views/sheets
            markAsRead(notification)
        }
    }
    
    // MARK: - Private Methods
    
    private func loadSettings(for uid: String) {
        settingsListener = db.collection("users").document(uid).collection("settings").document("notifications")
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.handleError("Failed to load settings: \(error.localizedDescription)")
                        return
                    }
                    
                    if let snapshot = snapshot, snapshot.exists {
                        do {
                            let loadedSettings = try snapshot.data(as: NotificationSettings.self)
                            self?.settings = loadedSettings
                        } catch {
                            self?.handleError("Failed to decode settings: \(error.localizedDescription)")
                        }
                    } else {
                        // Create default settings if none exist
                        self?.updateSettings(NotificationSettings())
                    }
                    
                    self?.isLoading = false
                }
            }
    }
    
    private func loadNotifications(for uid: String) {
        notificationsListener = db.collection("users").document(uid).collection("notifications")
            .order(by: "createdDate", descending: true)
            .limit(to: 100) // Limit to most recent 100 notifications
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.handleError("Failed to load notifications: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        self?.notifications = []
                        return
                    }
                    
                    self?.notifications = documents.compactMap { doc -> NotificationItem? in
                        do {
                            return try doc.data(as: NotificationItem.self)
                        } catch {
                            print("Failed to decode notification: \(error)")
                            return nil
                        }
                    }
                }
            }
    }
    
    private func snoozeNotification(_ notification: NotificationItem) {
        // Create a new notification scheduled for 1 hour from now
        let snoozeDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        
        createNotification(
            type: notification.type,
            title: notification.title,
            message: notification.message,
            priority: notification.priority,
            scheduledDate: snoozeDate,
            sifId: notification.sifId,
            metadata: notification.metadata
        )
        
        // Mark original as read
        markAsRead(notification)
    }
    
    private func handleError(_ message: String) {
        self.errorMessage = message
        self.showingError = true
        self.isLoading = false
    }
    
    // MARK: - Static Helper Methods
    
    /// Create a notification for a received SIF
    static func createSIFReceivedNotification(sifId: String, senderName: String, subject: String) -> NotificationItem {
        NotificationItem(
            type: .sifReceived,
            title: "New SIF from \(senderName)",
            message: subject,
            sifId: sifId
        )
    }
    
    /// Create a notification for a scheduled SIF
    static func createSIFScheduledNotification(sifId: String, recipientName: String, scheduledDate: Date) -> NotificationItem {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        
        return NotificationItem(
            type: .sifScheduled,
            title: "SIF Scheduled",
            message: "Your SIF to \(recipientName) is scheduled for \(formatter.string(from: scheduledDate))",
            scheduledDate: scheduledDate,
            sifId: sifId
        )
    }
    
    /// Create a notification for a delivered SIF
    static func createSIFDeliveredNotification(sifId: String, recipientName: String) -> NotificationItem {
        NotificationItem(
            type: .sifDelivered,
            title: "SIF Delivered",
            message: "Your SIF to \(recipientName) has been delivered",
            sifId: sifId
        )
    }
}