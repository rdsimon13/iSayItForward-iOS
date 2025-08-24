import Foundation
import UserNotifications
import UIKit
import Combine

// MARK: - Notification Service
class NotificationService: NSObject, ObservableObject {
    @Published var notifications: [Notification] = []
    @Published var unreadCount: Int = 0
    @Published var isPermissionGranted: Bool = false
    @Published var deviceToken: String?
    
    private let authService = AuthenticationService.shared
    private var cancellables = Set<AnyCancellable>()
    private let notificationCenter = UNUserNotificationCenter.current()
    private let notificationStorage = NotificationStorage()
    private let notificationQueue = NotificationQueue()
    
    static let shared = NotificationService()
    
    override init() {
        super.init()
        setupNotificationCenter()
        setupAuthenticationListener()
        loadNotifications()
    }
    
    // MARK: - Setup and Configuration
    private func setupNotificationCenter() {
        notificationCenter.delegate = self
    }
    
    private func setupAuthenticationListener() {
        authService.$isAuthenticated
            .sink { [weak self] isAuthenticated in
                if isAuthenticated {
                    self?.requestPermissions()
                    self?.loadNotifications()
                } else {
                    self?.clearNotifications()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Permission Management
    func requestPermissions() async {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .badge, .sound, .providesAppNotificationSettings]
            )
            
            await MainActor.run {
                self.isPermissionGranted = granted
            }
            
            if granted {
                await registerForRemoteNotifications()
            }
        } catch {
            print("Error requesting notification permissions: \(error)")
        }
    }
    
    func checkPermissions() async {
        let settings = await notificationCenter.notificationSettings()
        await MainActor.run {
            self.isPermissionGranted = settings.authorizationStatus == .authorized
        }
    }
    
    @MainActor
    private func registerForRemoteNotifications() async {
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    // MARK: - APNs Token Management
    func setDeviceToken(_ token: Data) {
        let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()
        DispatchQueue.main.async {
            self.deviceToken = tokenString
        }
        // Here you would typically send the token to your backend
        sendTokenToBackend(tokenString)
    }
    
    private func sendTokenToBackend(_ token: String) {
        // Implementation for sending token to backend
        print("📱 Device token registered: \(token)")
    }
    
    // MARK: - Notification Management
    func addNotification(_ notification: Notification) {
        DispatchQueue.main.async {
            // Check if notification already exists
            if !self.notifications.contains(where: { $0.id == notification.id }) {
                self.notifications.insert(notification, at: 0)
                self.updateUnreadCount()
                self.saveNotifications()
                
                // Schedule local notification if needed
                if notification.type.allowsActions {
                    self.scheduleLocalNotification(notification)
                }
            }
        }
    }
    
    func markAsRead(_ notificationId: String) {
        DispatchQueue.main.async {
            if let index = self.notifications.firstIndex(where: { $0.id == notificationId }) {
                self.notifications[index].markAsRead()
                self.updateUnreadCount()
                self.saveNotifications()
            }
        }
    }
    
    func markAllAsRead() {
        DispatchQueue.main.async {
            for index in self.notifications.indices {
                self.notifications[index].markAsRead()
            }
            self.updateUnreadCount()
            self.saveNotifications()
        }
    }
    
    func deleteNotification(_ notificationId: String) {
        DispatchQueue.main.async {
            self.notifications.removeAll { $0.id == notificationId }
            self.updateUnreadCount()
            self.saveNotifications()
            
            // Cancel pending local notification
            self.notificationCenter.removePendingNotificationRequests(withIdentifiers: [notificationId])
        }
    }
    
    func archiveNotification(_ notificationId: String) {
        DispatchQueue.main.async {
            if let index = self.notifications.firstIndex(where: { $0.id == notificationId }) {
                self.notifications[index].updateState(.archived)
                self.saveNotifications()
            }
        }
    }
    
    func clearAllNotifications() {
        DispatchQueue.main.async {
            self.notifications.removeAll()
            self.unreadCount = 0
            self.saveNotifications()
            self.notificationCenter.removeAllPendingNotificationRequests()
        }
    }
    
    private func clearNotifications() {
        DispatchQueue.main.async {
            self.notifications.removeAll()
            self.unreadCount = 0
        }
    }
    
    // MARK: - Filtering and Sorting
    func filteredNotifications(filter: NotificationFilter, category: NotificationCategory? = nil) -> [Notification] {
        var filtered = notifications
        
        // Apply category filter
        if let category = category {
            filtered = filtered.filter { $0.type.category == category }
        }
        
        // Apply state filter
        switch filter {
        case .all:
            filtered = filtered.filter { $0.state != .archived }
        case .unread:
            filtered = filtered.filter { !$0.isRead && $0.state != .archived }
        case .read:
            filtered = filtered.filter { $0.isRead && $0.state != .archived }
        case .archived:
            filtered = filtered.filter { $0.state == .archived }
        case .failed:
            filtered = filtered.filter { $0.state == .failed }
        case .scheduled:
            filtered = filtered.filter { $0.isScheduled }
        }
        
        return filtered
    }
    
    func sortedNotifications(_ notifications: [Notification], by sort: NotificationSort) -> [Notification] {
        switch sort {
        case .newest:
            return notifications.sorted { $0.createdAt > $1.createdAt }
        case .oldest:
            return notifications.sorted { $0.createdAt < $1.createdAt }
        case .priority:
            return notifications.sorted { first, second in
                if first.priority == second.priority {
                    return first.createdAt > second.createdAt
                }
                return first.priority.rawValue > second.priority.rawValue
            }
        case .type:
            return notifications.sorted { first, second in
                if first.type.category == second.type.category {
                    return first.createdAt > second.createdAt
                }
                return first.type.category.rawValue < second.type.category.rawValue
            }
        }
    }
    
    // MARK: - Local Notification Scheduling
    private func scheduleLocalNotification(_ notification: Notification) {
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.body
        content.sound = .default
        content.badge = NSNumber(value: unreadCount + 1)
        
        // Add category for actions
        if notification.type.allowsActions {
            content.categoryIdentifier = notification.type.rawValue
        }
        
        // Add payload
        if let payload = notification.payload {
            content.userInfo = try? JSONEncoder().encode(payload).jsonObject() ?? [:]
        }
        
        let request = UNNotificationRequest(
            identifier: notification.id,
            content: content,
            trigger: nil // Immediate delivery
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    // MARK: - Storage
    private func loadNotifications() {
        guard authService.isAuthenticated else { return }
        
        Task {
            let loadedNotifications = await notificationStorage.loadNotifications()
            await MainActor.run {
                self.notifications = loadedNotifications
                self.updateUnreadCount()
            }
        }
    }
    
    private func saveNotifications() {
        Task {
            await notificationStorage.saveNotifications(notifications)
        }
    }
    
    private func updateUnreadCount() {
        unreadCount = notifications.filter { !$0.isRead && $0.state != .archived }.count
        
        // Update app badge
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = self.unreadCount
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.alert, .badge, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let notificationId = response.notification.request.identifier
        
        // Handle notification actions
        switch response.actionIdentifier {
        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification
            markAsRead(notificationId)
            handleNotificationTap(notificationId)
        case "MARK_READ":
            markAsRead(notificationId)
        case "DELETE":
            deleteNotification(notificationId)
        case "ARCHIVE":
            archiveNotification(notificationId)
        default:
            break
        }
        
        completionHandler()
    }
    
    private func handleNotificationTap(_ notificationId: String) {
        // Handle deep linking based on notification payload
        if let notification = notifications.first(where: { $0.id == notificationId }),
           let payload = notification.payload,
           let deepLink = payload.deepLink {
            handleDeepLink(deepLink)
        }
    }
    
    private func handleDeepLink(_ deepLink: String) {
        // Implementation for deep linking
        print("🔗 Handling deep link: \(deepLink)")
        // Post notification for deep link handling
        NotificationCenter.default.post(name: .handleDeepLink, object: deepLink)
    }
}

// MARK: - Notification Names
extension Foundation.Notification.Name {
    static let handleDeepLink = Foundation.Notification.Name("handleDeepLink")
}

// MARK: - Data Extension
extension Data {
    func jsonObject() throws -> [String: Any] {
        return try JSONSerialization.jsonObject(with: self, options: []) as? [String: Any] ?? [:]
    }
}