import Foundation
import UserNotifications

// MARK: - Notification Scheduler
class NotificationScheduler: ObservableObject {
    
    static let shared = NotificationScheduler()
    
    @Published var scheduledNotifications: [UNNotificationRequest] = []
    @Published var isLoading = false
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    private init() {
        loadScheduledNotifications()
    }
    
    // MARK: - Schedule Local Notifications
    func scheduleLocalNotification(
        id: String = UUID().uuidString,
        title: String,
        body: String,
        subtitle: String? = nil,
        date: Date,
        type: NotificationType,
        actions: [NotificationAction] = [],
        userInfo: [String: Any] = [:]
    ) throws {
        
        // Check if we can schedule notifications
        guard date > Date() else {
            throw NotificationSchedulerError.pastDate
        }
        
        guard date.timeIntervalSinceNow <= NotificationConstants.Scheduling.maxScheduleAheadTime else {
            throw NotificationSchedulerError.tooFarInFuture
        }
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        if let subtitle = subtitle {
            content.subtitle = subtitle
        }
        
        // Add custom user info
        var combinedUserInfo = userInfo
        combinedUserInfo[NotificationConstants.PayloadKeys.notificationId] = id
        combinedUserInfo[NotificationConstants.PayloadKeys.notificationType] = type.rawValue
        content.userInfo = combinedUserInfo
        
        // Set category for actions
        content.categoryIdentifier = getCategoryIdentifier(for: type)
        
        // Create trigger
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        // Create request
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        
        // Schedule notification
        notificationCenter.add(request) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Failed to schedule notification: \(error)")
                } else {
                    self?.loadScheduledNotifications()
                }
            }
        }
        
        // Register category and actions if provided
        if !actions.isEmpty {
            registerNotificationCategory(for: type, with: actions)
        }
    }
    
    // MARK: - Schedule Reminder
    func scheduleReminder(
        for notification: Notification,
        at date: Date,
        customMessage: String? = nil
    ) throws {
        let title = "Reminder: \(NotificationFormatter.formatTitle(for: notification))"
        let body = customMessage ?? "Don't forget to check this notification: \(NotificationFormatter.formatMessage(for: notification, truncateAt: 100))"
        
        var userInfo: [String: Any] = [:]
        if let originalId = notification.id {
            userInfo["original_notification_id"] = originalId
        }
        
        try scheduleLocalNotification(
            title: title,
            body: body,
            date: date,
            type: .reminderScheduled,
            userInfo: userInfo
        )
    }
    
    // MARK: - Schedule SIF Delivery Reminder
    func scheduleSIFDeliveryReminder(
        sifId: String,
        recipientName: String,
        deliveryDate: Date
    ) throws {
        let reminderDate = Calendar.current.date(byAdding: .hour, value: -1, to: deliveryDate) ?? deliveryDate
        
        let title = "SIF Delivery Reminder"
        let body = "Your SIF to \(recipientName) will be delivered in 1 hour"
        
        let userInfo: [String: Any] = [
            NotificationConstants.PayloadKeys.sifId: sifId,
            "recipient_name": recipientName,
            "delivery_date": deliveryDate.timeIntervalSince1970
        ]
        
        try scheduleLocalNotification(
            id: "sif-reminder-\(sifId)",
            title: title,
            body: body,
            date: reminderDate,
            type: .reminderScheduled,
            userInfo: userInfo
        )
    }
    
    // MARK: - Cancel Notifications
    func cancelNotification(withId id: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [id])
        loadScheduledNotifications()
    }
    
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        loadScheduledNotifications()
    }
    
    func cancelNotifications(withIds ids: [String]) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ids)
        loadScheduledNotifications()
    }
    
    // MARK: - Load Scheduled Notifications
    func loadScheduledNotifications() {
        notificationCenter.getPendingNotificationRequests { [weak self] requests in
            DispatchQueue.main.async {
                self?.scheduledNotifications = requests
            }
        }
    }
    
    // MARK: - Notification Categories and Actions
    private func registerNotificationCategory(for type: NotificationType, with actions: [NotificationAction]) {
        let unActions = actions.compactMap { createUNNotificationAction(from: $0) }
        
        let category = UNNotificationCategory(
            identifier: getCategoryIdentifier(for: type),
            actions: unActions,
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        notificationCenter.getNotificationCategories { existingCategories in
            var categories = existingCategories
            categories.insert(category)
            self.notificationCenter.setNotificationCategories(categories)
        }
    }
    
    private func createUNNotificationAction(from action: NotificationAction) -> UNNotificationAction? {
        let identifier = getActionIdentifier(for: action.type)
        
        var options: UNNotificationActionOptions = []
        if action.style.isDestructive {
            options.insert(.destructive)
        }
        if action.type == .reply {
            options.insert(.foreground)
        }
        
        if action.type == .reply {
            return UNTextInputNotificationAction(
                identifier: identifier,
                title: action.title,
                options: options,
                textInputButtonTitle: "Send",
                textInputPlaceholder: "Type your reply..."
            )
        } else {
            return UNNotificationAction(
                identifier: identifier,
                title: action.title,
                options: options
            )
        }
    }
    
    // MARK: - Identifier Helpers
    private func getCategoryIdentifier(for type: NotificationType) -> String {
        switch type {
        case .messageResponse:
            return NotificationConstants.CategoryIdentifiers.messageResponse
        case .impactMilestone:
            return NotificationConstants.CategoryIdentifiers.impactMilestone
        case .mention:
            return NotificationConstants.CategoryIdentifiers.mention
        case .systemNotification:
            return NotificationConstants.CategoryIdentifiers.systemNotification
        case .communityUpdate:
            return NotificationConstants.CategoryIdentifiers.communityUpdate
        case .sifDelivered:
            return NotificationConstants.CategoryIdentifiers.sifDelivered
        case .sifReceived:
            return NotificationConstants.CategoryIdentifiers.sifReceived
        case .reminderScheduled:
            return NotificationConstants.CategoryIdentifiers.reminderScheduled
        case .accountUpdate:
            return NotificationConstants.CategoryIdentifiers.accountUpdate
        case .newFeature:
            return NotificationConstants.CategoryIdentifiers.newFeature
        }
    }
    
    private func getActionIdentifier(for actionType: ActionType) -> String {
        switch actionType {
        case .reply:
            return NotificationConstants.ActionIdentifiers.reply
        case .view:
            return NotificationConstants.ActionIdentifiers.view
        case .dismiss:
            return NotificationConstants.ActionIdentifiers.dismiss
        case .markAsRead:
            return NotificationConstants.ActionIdentifiers.markAsRead
        case .delete:
            return NotificationConstants.ActionIdentifiers.delete
        case .share:
            return NotificationConstants.ActionIdentifiers.share
        case .archive:
            return NotificationConstants.ActionIdentifiers.archive
        case .openSIF:
            return NotificationConstants.ActionIdentifiers.openSIF
        case .openProfile:
            return NotificationConstants.ActionIdentifiers.openProfile
        case .scheduleReminder:
            return NotificationConstants.ActionIdentifiers.scheduleReminder
        default:
            return "CUSTOM_ACTION_\(actionType.rawValue.uppercased())"
        }
    }
    
    // MARK: - Utility Methods
    func getNotificationCount() -> Int {
        return scheduledNotifications.count
    }
    
    func isNotificationScheduled(withId id: String) -> Bool {
        return scheduledNotifications.contains { $0.identifier == id }
    }
    
    func getScheduledNotification(withId id: String) -> UNNotificationRequest? {
        return scheduledNotifications.first { $0.identifier == id }
    }
    
    func getNextScheduledDate() -> Date? {
        let dates = scheduledNotifications.compactMap { request -> Date? in
            guard let trigger = request.trigger as? UNCalendarNotificationTrigger else { return nil }
            return trigger.nextTriggerDate()
        }
        
        return dates.min()
    }
}

// MARK: - Error Types
enum NotificationSchedulerError: LocalizedError {
    case pastDate
    case tooFarInFuture
    case schedulingLimitReached
    case permissionDenied
    case invalidDate
    case systemError(Error)
    
    var errorDescription: String? {
        switch self {
        case .pastDate:
            return "Cannot schedule notifications for past dates"
        case .tooFarInFuture:
            return "Cannot schedule notifications more than 30 days in advance"
        case .schedulingLimitReached:
            return "Maximum number of scheduled notifications reached"
        case .permissionDenied:
            return "Notification permissions are required to schedule notifications"
        case .invalidDate:
            return "Invalid date provided for scheduling"
        case .systemError(let error):
            return "System error: \(error.localizedDescription)"
        }
    }
}