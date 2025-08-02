import Foundation
import UserNotifications

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isNotificationPermissionGranted: Bool = false
    
    private init() {
        checkNotificationPermission()
    }
    
    // MARK: - Permission Management
    func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isNotificationPermissionGranted = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func requestNotificationPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            
            DispatchQueue.main.async {
                self.isNotificationPermissionGranted = granted
            }
            
            return granted
        } catch {
            print("Error requesting notification permission: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Notification Scheduling
    func scheduleReportSubmissionNotification() {
        guard isNotificationPermissionGranted else {
            print("Notification permission not granted")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Report Submitted"
        content.body = "Your content report has been submitted successfully. We'll review it shortly."
        content.sound = .default
        
        // Schedule for immediate delivery (you can modify this as needed)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "report_submitted_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Report submission notification scheduled successfully")
            }
        }
    }
    
    func scheduleSIFDeliveryNotification(for sifTitle: String, deliveryDate: Date) {
        guard isNotificationPermissionGranted else {
            print("Notification permission not granted")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "SIF Delivered"
        content.body = "Your SIF '\(sifTitle)' has been delivered successfully!"
        content.sound = .default
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: deliveryDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "sif_delivery_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling SIF delivery notification: \(error.localizedDescription)")
            } else {
                print("SIF delivery notification scheduled for \(deliveryDate)")
            }
        }
    }
    
    // MARK: - Notification Management
    func removeAllPendingNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    func removeNotifications(withIdentifiers identifiers: [String]) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}