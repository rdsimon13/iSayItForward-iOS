import Foundation
import UserNotifications

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isNotificationPermissionGranted: Bool = false
    @Published var lastError: String?
    
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
                if !granted {
                    self.lastError = "Notification permission was denied by user"
                } else {
                    self.lastError = nil
                }
            }
            
            return granted
        } catch {
            DispatchQueue.main.async {
                self.lastError = "Error requesting notification permission: \(error.localizedDescription)"
            }
            print("Error requesting notification permission: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Notification Scheduling
    func scheduleReportSubmissionNotification() {
        guard isNotificationPermissionGranted else {
            lastError = "Notification permission not granted"
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
        
        UNUserNotificationCenter.current().add(request) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.lastError = "Error scheduling notification: \(error.localizedDescription)"
                    print("Error scheduling notification: \(error.localizedDescription)")
                } else {
                    self?.lastError = nil
                    print("Report submission notification scheduled successfully")
                }
            }
        }
    }
    
    func scheduleSIFDeliveryNotification(for sifTitle: String, deliveryDate: Date) {
        guard isNotificationPermissionGranted else {
            lastError = "Notification permission not granted"
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
        
        UNUserNotificationCenter.current().add(request) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.lastError = "Error scheduling SIF delivery notification: \(error.localizedDescription)"
                    print("Error scheduling SIF delivery notification: \(error.localizedDescription)")
                } else {
                    self?.lastError = nil
                    print("SIF delivery notification scheduled for \(deliveryDate)")
                }
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
    
    // MARK: - Error Handling
    func clearError() {
        lastError = nil
    }
}