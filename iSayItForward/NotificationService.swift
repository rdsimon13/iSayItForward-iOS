import Foundation
import UserNotifications
import FirebaseAuth
import FirebaseFirestore
import UIKit

// Service responsible for managing push notifications and delivery alerts
class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()
    
    @Published var notificationPermissionGranted = false
    @Published var pendingNotifications: [PendingNotification] = []
    
    private let db = Firestore.firestore()
    private var notificationObservers: [NSObjectProtocol] = []
    
    override init() {
        super.init()
        setupNotificationObservers()
    }
    
    deinit {
        notificationObservers.forEach { NotificationCenter.default.removeObserver($0) }
    }
    
    // MARK: - Permission Management
    
    func requestNotificationPermissions() async {
        let center = UNUserNotificationCenter.current()
        
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            DispatchQueue.main.async {
                self.notificationPermissionGranted = granted
            }
            
            if granted {
                await registerForRemoteNotifications()
            }
        } catch {
            print("Error requesting notification permissions: \(error)")
        }
    }
    
    func checkNotificationPermissions() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        
        DispatchQueue.main.async {
            self.notificationPermissionGranted = settings.authorizationStatus == .authorized
        }
    }
    
    @MainActor
    private func registerForRemoteNotifications() {
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    // MARK: - SIF Delivery Notifications
    
    func scheduleDeliveryNotification(for sif: SIFItem) async {
        guard notificationPermissionGranted else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "SIF Delivered Successfully"
        content.body = "Your SIF '\(sif.subject)' has been delivered to \(sif.recipients.joined(separator: ", "))"
        content.sound = .default
        content.badge = await getUnreadNotificationCount() + 1 as NSNumber
        
        // Add custom data
        content.userInfo = [
            "sifId": sif.id ?? "",
            "type": "delivery_success",
            "authorUid": sif.authorUid
        ]
        
        let request = UNNotificationRequest(
            identifier: "delivery-\(sif.id ?? UUID().uuidString)",
            content: content,
            trigger: nil
        )
        
        try? await UNUserNotificationCenter.current().add(request)
    }
    
    func scheduleDeliveryFailureNotification(for sif: SIFItem, reason: String) async {
        guard notificationPermissionGranted else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "SIF Delivery Failed"
        content.body = "Failed to deliver '\(sif.subject)': \(reason)"
        content.sound = .default
        content.badge = await getUnreadNotificationCount() + 1 as NSNumber
        
        content.userInfo = [
            "sifId": sif.id ?? "",
            "type": "delivery_failure",
            "authorUid": sif.authorUid,
            "reason": reason
        ]
        
        let request = UNNotificationRequest(
            identifier: "delivery-failure-\(sif.id ?? UUID().uuidString)",
            content: content,
            trigger: nil
        )
        
        try? await UNUserNotificationCenter.current().add(request)
    }
    
    func scheduleScheduledDeliveryReminder(for sif: SIFItem) async {
        guard notificationPermissionGranted else { return }
        guard sif.scheduledDate > Date() else { return }
        
        // Schedule notification 5 minutes before delivery
        let reminderDate = sif.scheduledDate.addingTimeInterval(-300) // 5 minutes before
        guard reminderDate > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Scheduled SIF Reminder"
        content.body = "Your SIF '\(sif.subject)' will be delivered in 5 minutes"
        content.sound = .default
        
        content.userInfo = [
            "sifId": sif.id ?? "",
            "type": "delivery_reminder",
            "authorUid": sif.authorUid
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: reminderDate.timeIntervalSinceNow,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "reminder-\(sif.id ?? UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        try? await UNUserNotificationCenter.current().add(request)
    }
    
    func scheduleExpirationWarning(for sif: SIFItem) async {
        guard notificationPermissionGranted else { return }
        guard let expirationDate = sif.expirationDate else { return }
        
        // Schedule notification 24 hours before expiration
        let warningDate = expirationDate.addingTimeInterval(-86400) // 24 hours before
        guard warningDate > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "SIF Expiring Soon"
        content.body = "Your SIF '\(sif.subject)' will expire in 24 hours"
        content.sound = .default
        
        content.userInfo = [
            "sifId": sif.id ?? "",
            "type": "expiration_warning",
            "authorUid": sif.authorUid
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: warningDate.timeIntervalSinceNow,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "expiration-\(sif.id ?? UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        try? await UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Received SIF Notifications
    
    func scheduleNewSIFNotification(for sif: SIFItem) async {
        guard notificationPermissionGranted else { return }
        guard let currentUser = Auth.auth().currentUser else { return }
        
        // Only notify if current user is a recipient
        guard sif.recipients.contains(currentUser.uid) || sif.recipients.contains(currentUser.email ?? "") else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "New SIF Received"
        content.body = "You received a new SIF: '\(sif.subject)'"
        content.sound = .default
        content.badge = await getUnreadNotificationCount() + 1 as NSNumber
        
        content.userInfo = [
            "sifId": sif.id ?? "",
            "type": "new_sif",
            "authorUid": sif.authorUid
        ]
        
        let request = UNNotificationRequest(
            identifier: "new-sif-\(sif.id ?? UUID().uuidString)",
            content: content,
            trigger: nil
        )
        
        try? await UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - QR Code Notifications
    
    func scheduleSIFScannedNotification(for sif: SIFItem, scannerInfo: String) async {
        guard notificationPermissionGranted else { return }
        guard let currentUser = Auth.auth().currentUser else { return }
        guard sif.authorUid == currentUser.uid else { return } // Only notify author
        
        let content = UNMutableNotificationContent()
        content.title = "SIF QR Code Scanned"
        content.body = "Your SIF '\(sif.subject)' was accessed via QR code"
        content.sound = .default
        
        content.userInfo = [
            "sifId": sif.id ?? "",
            "type": "qr_scanned",
            "authorUid": sif.authorUid,
            "scannerInfo": scannerInfo
        ]
        
        let request = UNNotificationRequest(
            identifier: "qr-scan-\(sif.id ?? UUID().uuidString)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        try? await UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Notification Management
    
    func cancelNotificationsForSIF(_ sifId: String) async {
        let center = UNUserNotificationCenter.current()
        let identifiers = [
            "delivery-\(sifId)",
            "delivery-failure-\(sifId)",
            "reminder-\(sifId)",
            "expiration-\(sifId)",
            "new-sif-\(sifId)"
        ]
        
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }
    
    func getAllPendingNotifications() async {
        let center = UNUserNotificationCenter.current()
        let requests = await center.pendingNotificationRequests()
        
        let notifications = requests.map { request in
            PendingNotification(
                id: request.identifier,
                title: request.content.title,
                body: request.content.body,
                scheduledDate: (request.trigger as? UNTimeIntervalNotificationTrigger)?.nextTriggerDate(),
                userInfo: request.content.userInfo
            )
        }
        
        DispatchQueue.main.async {
            self.pendingNotifications = notifications
        }
    }
    
    func clearAllNotifications() async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
        
        DispatchQueue.main.async {
            self.pendingNotifications.removeAll()
        }
    }
    
    private func getUnreadNotificationCount() async -> Int {
        let center = UNUserNotificationCenter.current()
        let delivered = await center.deliveredNotifications()
        return delivered.count
    }
    
    // MARK: - Notification Observers
    
    private func setupNotificationObservers() {
        // Listen for app becoming active to update badge count
        let observer1 = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task {
                await self.checkNotificationPermissions()
                await self.getAllPendingNotifications()
            }
        }
        
        // Listen for notification responses
        let observer2 = NotificationCenter.default.addObserver(
            forName: .notificationResponseReceived,
            object: nil,
            queue: .main
        ) { notification in
            if let userInfo = notification.userInfo as? [String: Any] {
                self.handleNotificationResponse(userInfo)
            }
        }
        
        notificationObservers = [observer1, observer2]
    }
    
    private func handleNotificationResponse(_ userInfo: [String: Any]) {
        guard let sifId = userInfo["sifId"] as? String,
              let type = userInfo["type"] as? String else { return }
        
        switch type {
        case "delivery_success":
            // Navigate to SIF detail or show success message
            NotificationCenter.default.post(name: .navigateToSIF, object: sifId)
            
        case "delivery_failure":
            // Navigate to failed SIF or show retry options
            NotificationCenter.default.post(name: .showDeliveryFailure, object: userInfo)
            
        case "new_sif":
            // Navigate to received SIF
            NotificationCenter.default.post(name: .navigateToReceivedSIF, object: sifId)
            
        case "qr_scanned":
            // Navigate to SIF analytics or detail
            NotificationCenter.default.post(name: .navigateToSIF, object: sifId)
            
        default:
            break
        }
    }
    
    // MARK: - Badge Management
    
    func updateBadgeCount() async {
        let center = UNUserNotificationCenter.current()
        let delivered = await center.deliveredNotifications()
        
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = delivered.count
        }
    }
    
    func clearBadge() {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
}

// MARK: - Supporting Models

struct PendingNotification: Identifiable {
    let id: String
    let title: String
    let body: String
    let scheduledDate: Date?
    let userInfo: [AnyHashable: Any]
}

// MARK: - Notification Names

extension Notification.Name {
    static let notificationResponseReceived = Notification.Name("notificationResponseReceived")
    static let navigateToSIF = Notification.Name("navigateToSIF")
    static let navigateToReceivedSIF = Notification.Name("navigateToReceivedSIF")
    static let showDeliveryFailure = Notification.Name("showDeliveryFailure")
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle notification tap
        NotificationCenter.default.post(
            name: .notificationResponseReceived,
            object: nil,
            userInfo: response.notification.request.content.userInfo
        )
        
        completionHandler()
    }
}

// MARK: - Integration with Services

extension SIFDeliveryService {
    func sendNotificationForDelivery(_ sif: SIFItem) async {
        if sif.notifyOnDelivery {
            await NotificationService.shared.scheduleDeliveryNotification(for: sif)
        }
    }
    
    func sendNotificationForFailure(_ sif: SIFItem, reason: String) async {
        await NotificationService.shared.scheduleDeliveryFailureNotification(for: sif, reason: reason)
    }
}

extension QRCodeService {
    func sendNotificationForQRScan(_ sif: SIFItem) async {
        await NotificationService.shared.scheduleSIFScannedNotification(for: sif, scannerInfo: "QR Code")
    }
}