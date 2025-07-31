import Foundation

// MARK: - Notification Storage
actor NotificationStorage {
    private let userDefaults = UserDefaults.standard
    private let notificationsKey = "stored_notifications"
    private let maxStoredNotifications = 500 // Limit to prevent excessive storage
    
    // MARK: - Save/Load Operations
    func saveNotifications(_ notifications: [Notification]) async {
        do {
            // Limit stored notifications to prevent excessive storage usage
            let notificationsToStore = Array(notifications.prefix(maxStoredNotifications))
            let data = try JSONEncoder().encode(notificationsToStore)
            userDefaults.set(data, forKey: notificationsKey)
        } catch {
            print("Error saving notifications: \(error)")
        }
    }
    
    func loadNotifications() async -> [Notification] {
        guard let data = userDefaults.data(forKey: notificationsKey) else {
            return []
        }
        
        do {
            let notifications = try JSONDecoder().decode([Notification].self, from: data)
            return notifications
        } catch {
            print("Error loading notifications: \(error)")
            return []
        }
    }
    
    // MARK: - Cleanup Operations
    func clearStoredNotifications() async {
        userDefaults.removeObject(forKey: notificationsKey)
    }
    
    func removeExpiredNotifications() async -> [Notification] {
        let notifications = await loadNotifications()
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        
        // Keep notifications from last 30 days or unread notifications
        let filteredNotifications = notifications.filter { notification in
            notification.createdAt > thirtyDaysAgo || !notification.isRead
        }
        
        await saveNotifications(filteredNotifications)
        return filteredNotifications
    }
    
    func getStorageStats() async -> (count: Int, sizeInBytes: Int) {
        guard let data = userDefaults.data(forKey: notificationsKey) else {
            return (0, 0)
        }
        
        let notifications = await loadNotifications()
        return (notifications.count, data.count)
    }
}

// MARK: - Storage Extensions
extension NotificationStorage {
    func exportNotifications() async -> Data? {
        let notifications = await loadNotifications()
        do {
            return try JSONEncoder().encode(notifications)
        } catch {
            print("Error exporting notifications: \(error)")
            return nil
        }
    }
    
    func importNotifications(from data: Data) async -> Bool {
        do {
            let notifications = try JSONDecoder().decode([Notification].self, from: data)
            await saveNotifications(notifications)
            return true
        } catch {
            print("Error importing notifications: \(error)")
            return false
        }
    }
}