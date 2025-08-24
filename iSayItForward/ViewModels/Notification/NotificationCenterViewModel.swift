import Foundation
import Combine
import SwiftUI

// MARK: - Notification Center ViewModel
@MainActor
class NotificationCenterViewModel: ObservableObject {
    @Published var notifications: [Notification] = []
    @Published var groupedNotifications: [String: [Notification]] = [:]
    @Published var selectedNotifications: Set<String> = []
    @Published var isSelectionMode: Bool = false
    @Published var isRefreshing: Bool = false
    @Published var selectedFilter: NotificationFilter = .all
    @Published var selectedCategory: NotificationCategory?
    @Published var showingFilterSheet: Bool = false
    @Published var showingBatchActionSheet: Bool = false
    
    private let notificationService = NotificationService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupSubscriptions()
    }
    
    // MARK: - Setup
    private func setupSubscriptions() {
        notificationService.$notifications
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notifications in
                self?.updateNotifications(notifications)
            }
            .store(in: &cancellables)
    }
    
    private func updateNotifications(_ allNotifications: [Notification]) {
        let filtered = notificationService.filteredNotifications(
            filter: selectedFilter,
            category: selectedCategory
        )
        
        notifications = notificationService.sortedNotifications(filtered, by: .newest)
        groupedNotifications = NotificationUtilities.groupNotifications(notifications)
    }
    
    // MARK: - Refresh Control
    func refreshNotifications() async {
        isRefreshing = true
        
        do {
            // Simulate network delay
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            // In a real app, this would fetch from backend
            await generateFreshNotifications()
            
        } catch {
            print("Refresh failed: \(error)")
        }
        
        isRefreshing = false
    }
    
    // MARK: - Filter Management
    func applyFilter(_ filter: NotificationFilter) {
        selectedFilter = filter
        updateNotifications(notificationService.notifications)
        exitSelectionMode()
    }
    
    func applyCategoryFilter(_ category: NotificationCategory?) {
        selectedCategory = category
        updateNotifications(notificationService.notifications)
        exitSelectionMode()
    }
    
    func clearFilters() {
        selectedFilter = .all
        selectedCategory = nil
        updateNotifications(notificationService.notifications)
        exitSelectionMode()
    }
    
    // MARK: - Selection Management
    func enterSelectionMode() {
        isSelectionMode = true
        selectedNotifications.removeAll()
    }
    
    func exitSelectionMode() {
        isSelectionMode = false
        selectedNotifications.removeAll()
    }
    
    func toggleNotificationSelection(_ notificationId: String) {
        if selectedNotifications.contains(notificationId) {
            selectedNotifications.remove(notificationId)
        } else {
            selectedNotifications.insert(notificationId)
        }
        
        // Exit selection mode if no notifications are selected
        if selectedNotifications.isEmpty {
            isSelectionMode = false
        }
    }
    
    func selectAllVisibleNotifications() {
        selectedNotifications = Set(notifications.map { $0.id })
    }
    
    func deselectAllNotifications() {
        selectedNotifications.removeAll()
    }
    
    // MARK: - Batch Actions
    func markSelectedAsRead() {
        for notificationId in selectedNotifications {
            notificationService.markAsRead(notificationId)
        }
        exitSelectionMode()
    }
    
    func deleteSelectedNotifications() {
        for notificationId in selectedNotifications {
            notificationService.deleteNotification(notificationId)
        }
        exitSelectionMode()
    }
    
    func archiveSelectedNotifications() {
        for notificationId in selectedNotifications {
            notificationService.archiveNotification(notificationId)
        }
        exitSelectionMode()
    }
    
    // MARK: - Individual Actions
    func markAsRead(_ notificationId: String) {
        notificationService.markAsRead(notificationId)
    }
    
    func deleteNotification(_ notificationId: String) {
        notificationService.deleteNotification(notificationId)
        
        // Remove from selection if selected
        selectedNotifications.remove(notificationId)
        
        // Exit selection mode if no notifications remain selected
        if selectedNotifications.isEmpty {
            isSelectionMode = false
        }
    }
    
    func archiveNotification(_ notificationId: String) {
        notificationService.archiveNotification(notificationId)
        
        // Remove from selection if selected
        selectedNotifications.remove(notificationId)
    }
    
    // MARK: - Navigation Helpers
    func handleNotificationTap(_ notification: Notification) {
        // Mark as read when tapped
        if !notification.isRead {
            markAsRead(notification.id)
        }
        
        // Handle deep linking
        if let payload = notification.payload, let deepLink = payload.deepLink {
            handleDeepLink(deepLink)
        }
    }
    
    private func handleDeepLink(_ deepLink: String) {
        guard let (path, parameters) = NotificationUtilities.parseDeepLink(deepLink) else {
            return
        }
        
        // Post notification for app-level deep link handling
        NotificationCenter.default.post(
            name: .handleDeepLink,
            object: nil,
            userInfo: ["path": path, "parameters": parameters]
        )
    }
    
    // MARK: - UI State
    var hasNotifications: Bool {
        return !notifications.isEmpty
    }
    
    var hasSelectedNotifications: Bool {
        return !selectedNotifications.isEmpty
    }
    
    var selectedNotificationsCount: Int {
        return selectedNotifications.count
    }
    
    var canPerformBatchActions: Bool {
        return hasSelectedNotifications
    }
    
    var allVisibleSelected: Bool {
        return notifications.count > 0 && selectedNotifications.count == notifications.count
    }
    
    // MARK: - Filter Info
    var activeFilterCount: Int {
        var count = 0
        if selectedFilter != .all { count += 1 }
        if selectedCategory != nil { count += 1 }
        return count
    }
    
    var filterDescription: String {
        var parts: [String] = []
        
        if selectedFilter != .all {
            parts.append(selectedFilter.displayName)
        }
        
        if let category = selectedCategory {
            parts.append(category.displayName)
        }
        
        if parts.isEmpty {
            return "All Notifications"
        } else {
            return parts.joined(separator: " • ")
        }
    }
    
    // MARK: - Sample Data Generation
    private func generateFreshNotifications() async {
        guard let currentUser = AuthenticationService.shared.currentAppUser else { return }
        
        let newNotifications = [
            Notification(
                title: "Message from Alex",
                body: "Thanks for the SIF! It made my day!",
                type: .messageReceived,
                payload: NotificationPayload.messagePayload(chatId: "chat_123", senderId: "user_alex"),
                recipientUID: currentUser.uid,
                priority: .normal
            ),
            Notification(
                title: "SIF Reminder",
                body: "Don't forget to send Mom a SIF for her birthday tomorrow!",
                type: .sifReminder,
                recipientUID: currentUser.uid,
                priority: .high
            )
        ]
        
        for notification in newNotifications {
            notificationService.addNotification(notification)
        }
    }
}