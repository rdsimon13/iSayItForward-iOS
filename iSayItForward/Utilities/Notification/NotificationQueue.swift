import Foundation
import Combine

// MARK: - Notification Queue
actor NotificationQueue {
    private var pendingNotifications: [QueuedNotification] = []
    private var isProcessing = false
    private let maxRetryAttempts = 3
    private let retryDelay: TimeInterval = 5.0
    
    // MARK: - Queued Notification
    struct QueuedNotification {
        let notification: Notification
        var retryCount: Int = 0
        let scheduledAt: Date
        var lastAttempt: Date?
        
        init(notification: Notification, scheduledAt: Date = Date()) {
            self.notification = notification
            self.scheduledAt = scheduledAt
        }
        
        var shouldRetry: Bool {
            retryCount < 3 && (lastAttempt == nil || Date().timeIntervalSince(lastAttempt!) > 5.0)
        }
    }
    
    // MARK: - Queue Management
    func enqueue(_ notification: Notification, scheduledAt: Date = Date()) async {
        let queuedNotification = QueuedNotification(notification: notification, scheduledAt: scheduledAt)
        pendingNotifications.append(queuedNotification)
        
        if !isProcessing {
            await processQueue()
        }
    }
    
    func processQueue() async {
        guard !isProcessing else { return }
        isProcessing = true
        
        while !pendingNotifications.isEmpty {
            let now = Date()
            
            // Find notifications ready to be processed
            let readyNotifications = pendingNotifications.enumerated().compactMap { index, queued -> (Int, QueuedNotification)? in
                if queued.scheduledAt <= now && queued.shouldRetry {
                    return (index, queued)
                }
                return nil
            }
            
            if readyNotifications.isEmpty {
                // Wait for next scheduled notification
                let nextScheduledTime = pendingNotifications.compactMap { $0.scheduledAt }.min()
                if let nextTime = nextScheduledTime {
                    let delay = max(1.0, nextTime.timeIntervalSince(now))
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                } else {
                    break
                }
            }
            
            // Process ready notifications
            for (index, queuedNotification) in readyNotifications.reversed() {
                await processNotification(queuedNotification, at: index)
            }
        }
        
        isProcessing = false
    }
    
    private func processNotification(_ queuedNotification: QueuedNotification, at index: Int) async {
        var notification = queuedNotification
        notification.retryCount += 1
        notification.lastAttempt = Date()
        
        let success = await deliverNotification(notification.notification)
        
        if success {
            // Remove successfully delivered notification
            pendingNotifications.remove(at: index)
        } else if notification.retryCount >= maxRetryAttempts {
            // Mark as failed and remove
            var failedNotification = notification.notification
            failedNotification.updateState(.failed)
            pendingNotifications.remove(at: index)
            
            // Notify about failure
            await handleDeliveryFailure(failedNotification)
        } else {
            // Update retry count for future attempts
            pendingNotifications[index] = notification
        }
    }
    
    private func deliverNotification(_ notification: Notification) async -> Bool {
        // Simulate notification delivery
        // In a real app, this would make API calls to your backend
        
        do {
            // Simulate network delay
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            
            // Simulate 90% success rate
            let success = Double.random(in: 0...1) < 0.9
            
            if success {
                print("✅ Notification delivered: \(notification.title)")
                await notifyDeliverySuccess(notification)
            } else {
                print("❌ Notification delivery failed: \(notification.title)")
            }
            
            return success
        } catch {
            print("❌ Error delivering notification: \(error)")
            return false
        }
    }
    
    private func notifyDeliverySuccess(_ notification: Notification) async {
        // Update notification state
        await MainActor.run {
            NotificationCenter.default.post(
                name: .notificationDelivered,
                object: notification.id
            )
        }
    }
    
    private func handleDeliveryFailure(_ notification: Notification) async {
        await MainActor.run {
            NotificationCenter.default.post(
                name: .notificationDeliveryFailed,
                object: notification.id
            )
        }
    }
    
    // MARK: - Queue Information
    func getQueueStatus() async -> (pending: Int, processing: Bool) {
        return (pendingNotifications.count, isProcessing)
    }
    
    func clearQueue() async {
        pendingNotifications.removeAll()
        isProcessing = false
    }
    
    func retryFailedNotifications() async {
        // Reset retry counts for failed notifications
        for index in pendingNotifications.indices {
            pendingNotifications[index].retryCount = 0
            pendingNotifications[index].lastAttempt = nil
        }
        
        if !isProcessing {
            await processQueue()
        }
    }
}

// MARK: - Notification Names
extension Foundation.Notification.Name {
    static let notificationDelivered = Foundation.Notification.Name("notificationDelivered")
    static let notificationDeliveryFailed = Foundation.Notification.Name("notificationDeliveryFailed")
}