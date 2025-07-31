import Foundation
import UserNotifications
import FirebaseFirestore
import FirebaseAuth
import UIKit

// MARK: - Notification Service
class NotificationService: NSObject, ObservableObject {
    
    static let shared = NotificationService()
    
    // MARK: - Published Properties
    @Published var notifications: [Notification] = []
    @Published var unreadCount: Int = 0
    @Published var isLoading: Bool = false
    @Published var deviceToken: String?
    @Published var error: NotificationServiceError?
    
    // MARK: - Private Properties
    private let db = Firestore.firestore()
    private let permissions = NotificationPermissions.shared
    private let scheduler = NotificationScheduler.shared
    private var notificationListener: ListenerRegistration?
    private var preferencesListener: ListenerRegistration?
    
    @Published var preferences: NotificationPreferences?
    
    override init() {
        super.init()
        setupNotificationCenter()
        setupAuthListener()
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - Setup Methods
    private func setupNotificationCenter() {
        UNUserNotificationCenter.current().delegate = self
    }
    
    private func setupAuthListener() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if let user = user {
                self?.loadUserData(userId: user.uid)
            } else {
                self?.cleanup()
            }
        }
    }
    
    private func loadUserData(userId: String) {
        loadNotificationPreferences(for: userId)
        startListeningForNotifications(userId: userId)
        loadNotifications(for: userId)
    }
    
    // MARK: - Push Notification Registration
    func registerForPushNotifications() {
        permissions.requestPermissions { [weak self] granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                self?.error = .permissionDenied
            }
        }
    }
    
    func didRegisterForRemoteNotifications(withDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        self.deviceToken = token
        
        // Store token locally
        UserDefaults.standard.set(token, forKey: NotificationConstants.UserDefaults.deviceToken)
        
        // Send token to server
        sendTokenToServer(token: token)
    }
    
    func didFailToRegisterForRemoteNotifications(withError error: Error) {
        print("Failed to register for remote notifications: \(error)")
        self.error = .registrationFailed(error)
    }
    
    private func sendTokenToServer(token: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let tokenData: [String: Any] = [
            "token": token,
            "userId": userId,
            "platform": "ios",
            "lastUpdated": Timestamp(),
            "isActive": true
        ]
        
        db.collection(NotificationConstants.Collections.notificationTokens)
            .document(userId)
            .setData(tokenData, merge: true) { [weak self] error in
                if let error = error {
                    print("Failed to save device token: \(error)")
                    self?.error = .tokenRegistrationFailed(error)
                }
            }
    }
    
    // MARK: - Notification Management
    func createNotification(
        userId: String,
        type: NotificationType,
        title: String,
        message: String,
        relatedSIFId: String? = nil,
        actionData: [String: String]? = nil,
        imageURL: String? = nil,
        deepLinkURL: String? = nil,
        groupId: String? = nil,
        priority: NotificationPriority = .normal,
        isSilent: Bool = false
    ) {
        let notification = Notification(
            userId: userId,
            type: type,
            title: title,
            message: message,
            isSilent: isSilent,
            priority: priority
        )
        
        // Set optional properties
        var mutableNotification = notification
        mutableNotification.relatedSIFId = relatedSIFId
        mutableNotification.actionData = actionData
        mutableNotification.imageURL = imageURL
        mutableNotification.deepLinkURL = deepLinkURL
        mutableNotification.groupId = groupId
        mutableNotification.category = type.category.rawValue
        
        saveNotification(mutableNotification)
    }
    
    private func saveNotification(_ notification: Notification) {
        do {
            _ = try db.collection(NotificationConstants.Collections.notifications)
                .addDocument(from: notification) { [weak self] error in
                    if let error = error {
                        print("Failed to save notification: \(error)")
                        self?.error = .saveFailed(error)
                    }
                }
        } catch {
            print("Failed to encode notification: \(error)")
            self.error = .encodingFailed(error)
        }
    }
    
    func markAsRead(notificationId: String) {
        db.collection(NotificationConstants.Collections.notifications)
            .document(notificationId)
            .updateData(["isRead": true]) { [weak self] error in
                if let error = error {
                    print("Failed to mark notification as read: \(error)")
                    self?.error = .updateFailed(error)
                } else {
                    self?.updateLocalNotification(id: notificationId, isRead: true)
                }
            }
    }
    
    func markAllAsRead(for userId: String) {
        let batch = db.batch()
        
        let unreadNotifications = notifications.filter { !$0.isRead && $0.userId == userId }
        
        for notification in unreadNotifications {
            if let id = notification.id {
                let ref = db.collection(NotificationConstants.Collections.notifications).document(id)
                batch.updateData(["isRead": true], forDocument: ref)
            }
        }
        
        batch.commit { [weak self] error in
            if let error = error {
                print("Failed to mark all notifications as read: \(error)")
                self?.error = .batchUpdateFailed(error)
            } else {
                self?.updateAllLocalNotificationsAsRead()
            }
        }
    }
    
    func deleteNotification(notificationId: String) {
        db.collection(NotificationConstants.Collections.notifications)
            .document(notificationId)
            .delete { [weak self] error in
                if let error = error {
                    print("Failed to delete notification: \(error)")
                    self?.error = .deleteFailed(error)
                } else {
                    self?.removeLocalNotification(id: notificationId)
                }
            }
    }
    
    // MARK: - Local Notification Updates
    private func updateLocalNotification(id: String, isRead: Bool) {
        if let index = notifications.firstIndex(where: { $0.id == id }) {
            notifications[index].isRead = isRead
            updateUnreadCount()
        }
    }
    
    private func updateAllLocalNotificationsAsRead() {
        for index in notifications.indices {
            notifications[index].isRead = true
        }
        updateUnreadCount()
    }
    
    private func removeLocalNotification(id: String) {
        notifications.removeAll { $0.id == id }
        updateUnreadCount()
    }
    
    private func updateUnreadCount() {
        unreadCount = notifications.filter { !$0.isRead }.count
        updateBadgeCount()
    }
    
    // MARK: - Badge Management
    private func updateBadgeCount() {
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = self.unreadCount
            UserDefaults.standard.set(self.unreadCount, forKey: NotificationConstants.UserDefaults.badgeCount)
        }
    }
    
    func clearBadge() {
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }
    
    // MARK: - Data Loading
    private func loadNotifications(for userId: String) {
        isLoading = true
        
        db.collection(NotificationConstants.Collections.notifications)
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdDate", descending: true)
            .limit(to: NotificationConstants.NotificationCenter.maxNotificationsToShow)
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        print("Failed to load notifications: \(error)")
                        self?.error = .loadFailed(error)
                        return
                    }
                    
                    guard let documents = snapshot?.documents else { return }
                    
                    self?.notifications = documents.compactMap { document in
                        try? document.data(as: Notification.self)
                    }
                    
                    self?.updateUnreadCount()
                }
            }
    }
    
    private func startListeningForNotifications(userId: String) {
        notificationListener?.remove()
        
        notificationListener = db.collection(NotificationConstants.Collections.notifications)
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdDate", descending: true)
            .limit(to: NotificationConstants.NotificationCenter.maxNotificationsToShow)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Notification listener error: \(error)")
                    self?.error = .listenerFailed(error)
                    return
                }
                
                guard let snapshot = snapshot else { return }
                
                DispatchQueue.main.async {
                    self?.notifications = snapshot.documents.compactMap { document in
                        try? document.data(as: Notification.self)
                    }
                    
                    self?.updateUnreadCount()
                }
            }
    }
    
    // MARK: - Notification Preferences
    private func loadNotificationPreferences(for userId: String) {
        preferencesListener?.remove()
        
        preferencesListener = db.collection(NotificationConstants.Collections.notificationPreferences)
            .document(userId)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Preferences listener error: \(error)")
                    return
                }
                
                DispatchQueue.main.async {
                    if let snapshot = snapshot, snapshot.exists {
                        self?.preferences = try? snapshot.data(as: NotificationPreferences.self)
                    } else {
                        // Create default preferences
                        let defaultPreferences = NotificationPreferences(userId: userId)
                        self?.preferences = defaultPreferences
                        self?.savePreferences(defaultPreferences)
                    }
                }
            }
    }
    
    func updatePreferences(_ preferences: NotificationPreferences) {
        self.preferences = preferences
        savePreferences(preferences)
    }
    
    private func savePreferences(_ preferences: NotificationPreferences) {
        do {
            try db.collection(NotificationConstants.Collections.notificationPreferences)
                .document(preferences.userId)
                .setData(from: preferences)
        } catch {
            print("Failed to save preferences: \(error)")
            self.error = .preferencesSaveFailed(error)
        }
    }
    
    // MARK: - In-App Notification Handling
    func handleInAppNotification(_ notification: Notification) {
        guard let preferences = preferences,
              preferences.isNotificationAllowed(for: notification.type) else {
            return
        }
        
        // Add to local notifications if not already present
        if !notifications.contains(where: { $0.id == notification.id }) {
            notifications.insert(notification, at: 0)
            updateUnreadCount()
        }
        
        // Show in-app notification if app is active
        if UIApplication.shared.applicationState == .active {
            showInAppNotification(notification)
        }
    }
    
    private func showInAppNotification(_ notification: Notification) {
        // This would trigger an in-app notification banner
        // Implementation would depend on the UI framework used
        NotificationCenter.default.post(
            name: .showInAppNotification,
            object: notification
        )
    }
    
    // MARK: - Cleanup
    private func cleanup() {
        notificationListener?.remove()
        preferencesListener?.remove()
        notifications.removeAll()
        preferences = nil
        unreadCount = 0
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationService: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        handleNotificationResponse(response)
        completionHandler()
    }
    
    private func handleNotificationResponse(_ response: UNNotificationResponse) {
        let userInfo = response.notification.request.content.userInfo
        
        // Extract notification data
        guard let notificationId = userInfo[NotificationConstants.PayloadKeys.notificationId] as? String else {
            return
        }
        
        // Handle different action types
        switch response.actionIdentifier {
        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification
            handleNotificationTap(notificationId: notificationId, userInfo: userInfo)
            
        case NotificationConstants.ActionIdentifiers.markAsRead:
            markAsRead(notificationId: notificationId)
            
        case NotificationConstants.ActionIdentifiers.delete:
            deleteNotification(notificationId: notificationId)
            
        case NotificationConstants.ActionIdentifiers.reply:
            if let textResponse = response as? UNTextInputNotificationResponse {
                handleReplyAction(notificationId: notificationId, replyText: textResponse.userText, userInfo: userInfo)
            }
            
        default:
            break
        }
    }
    
    private func handleNotificationTap(notificationId: String, userInfo: [AnyHashable: Any]) {
        // Mark as read
        markAsRead(notificationId: notificationId)
        
        // Handle deep linking
        if let deepLinkURL = userInfo[NotificationConstants.PayloadKeys.deepLinkURL] as? String,
           let url = URL(string: deepLinkURL) {
            NotificationCenter.default.post(name: .handleDeepLink, object: url)
        }
        
        // Navigate to notification detail or related content
        NotificationCenter.default.post(name: .navigateToNotification, object: notificationId)
    }
    
    private func handleReplyAction(notificationId: String, replyText: String, userInfo: [AnyHashable: Any]) {
        // Mark original notification as read
        markAsRead(notificationId: notificationId)
        
        // Handle the reply (this would integrate with your SIF system)
        if let sifId = userInfo[NotificationConstants.PayloadKeys.sifId] as? String {
            NotificationCenter.default.post(
                name: .handleNotificationReply,
                object: ["sifId": sifId, "replyText": replyText]
            )
        }
    }
}

// MARK: - Error Types
enum NotificationServiceError: LocalizedError {
    case permissionDenied
    case registrationFailed(Error)
    case tokenRegistrationFailed(Error)
    case saveFailed(Error)
    case updateFailed(Error)
    case deleteFailed(Error)
    case loadFailed(Error)
    case encodingFailed(Error)
    case listenerFailed(Error)
    case batchUpdateFailed(Error)
    case preferencesSaveFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return NotificationConstants.ErrorMessages.permissionDenied
        case .registrationFailed:
            return NotificationConstants.ErrorMessages.registrationFailed
        case .tokenRegistrationFailed:
            return NotificationConstants.ErrorMessages.tokenRegistrationFailed
        case .saveFailed, .updateFailed, .deleteFailed, .loadFailed, .encodingFailed, .listenerFailed, .batchUpdateFailed, .preferencesSaveFailed:
            return NotificationConstants.ErrorMessages.unknownError
        }
    }
}

// MARK: - Notification Names
extension Foundation.Notification.Name {
    static let showInAppNotification = Foundation.Notification.Name("showInAppNotification")
    static let handleDeepLink = Foundation.Notification.Name("handleDeepLink")
    static let navigateToNotification = Foundation.Notification.Name("navigateToNotification")
    static let handleNotificationReply = Foundation.Notification.Name("handleNotificationReply")
}