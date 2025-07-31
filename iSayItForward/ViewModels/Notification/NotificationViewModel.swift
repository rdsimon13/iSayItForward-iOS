import Foundation
import Combine
import SwiftUI

// MARK: - Main Notification ViewModel
@MainActor
class NotificationViewModel: ObservableObject {
    @Published var notifications: [Notification] = []
    @Published var unreadCount: Int = 0
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var selectedFilter: NotificationFilter = .all
    @Published var selectedCategory: NotificationCategory?
    @Published var selectedSort: NotificationSort = .newest
    @Published var searchText: String = ""
    @Published var isPermissionGranted: Bool = false
    
    private let notificationService = NotificationService.shared
    private let authService = AuthenticationService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupSubscriptions()
        loadInitialData()
    }
    
    // MARK: - Setup
    private func setupSubscriptions() {
        // Subscribe to notification service updates
        notificationService.$notifications
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notifications in
                self?.notifications = notifications
                self?.applyFiltersAndSort()
            }
            .store(in: &cancellables)
        
        notificationService.$unreadCount
            .receive(on: DispatchQueue.main)
            .assign(to: \.unreadCount, on: self)
            .store(in: &cancellables)
        
        notificationService.$isPermissionGranted
            .receive(on: DispatchQueue.main)
            .assign(to: \.isPermissionGranted, on: self)
            .store(in: &cancellables)
        
        // Subscribe to filter/sort changes
        Publishers.CombineLatest4($selectedFilter, $selectedCategory, $selectedSort, $searchText)
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _, _, _, _ in
                self?.applyFiltersAndSort()
            }
            .store(in: &cancellables)
    }
    
    private func loadInitialData() {
        Task {
            await checkPermissions()
            await refreshNotifications()
        }
    }
    
    // MARK: - Data Management
    func refreshNotifications() async {
        isLoading = true
        error = nil
        
        do {
            // Simulate refresh delay
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // In a real app, this would fetch from backend
            await generateSampleNotifications()
            
            applyFiltersAndSort()
        } catch {
            self.error = "Failed to refresh notifications: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func loadMoreNotifications() async {
        // Implementation for pagination
        print("Loading more notifications...")
    }
    
    // MARK: - Notification Actions
    func markAsRead(_ notificationId: String) {
        notificationService.markAsRead(notificationId)
        
        // Update local state immediately for responsive UI
        if let index = notifications.firstIndex(where: { $0.id == notificationId }) {
            notifications[index].markAsRead()
        }
    }
    
    func markAllAsRead() {
        notificationService.markAllAsRead()
        
        // Update local state
        for index in notifications.indices {
            notifications[index].markAsRead()
        }
        
        unreadCount = 0
    }
    
    func deleteNotification(_ notificationId: String) {
        notificationService.deleteNotification(notificationId)
        
        // Update local state
        notifications.removeAll { $0.id == notificationId }
    }
    
    func archiveNotification(_ notificationId: String) {
        notificationService.archiveNotification(notificationId)
        
        // Update local state
        if let index = notifications.firstIndex(where: { $0.id == notificationId }) {
            notifications[index].updateState(.archived)
        }
    }
    
    // MARK: - Batch Actions
    func deleteAllRead() {
        let readNotifications = notifications.filter { $0.isRead }
        
        for notification in readNotifications {
            notificationService.deleteNotification(notification.id)
        }
        
        notifications.removeAll { $0.isRead }
    }
    
    func archiveAllRead() {
        let readNotifications = notifications.filter { $0.isRead }
        
        for notification in readNotifications {
            notificationService.archiveNotification(notification.id)
        }
        
        // Update local state
        for index in notifications.indices {
            if notifications[index].isRead {
                notifications[index].updateState(.archived)
            }
        }
        
        applyFiltersAndSort()
    }
    
    // MARK: - Filtering and Sorting
    private func applyFiltersAndSort() {
        var filtered = notificationService.filteredNotifications(
            filter: selectedFilter,
            category: selectedCategory
        )
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { notification in
                notification.title.localizedCaseInsensitiveContains(searchText) ||
                notification.body.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply sorting
        filtered = notificationService.sortedNotifications(filtered, by: selectedSort)
        
        notifications = filtered
    }
    
    // MARK: - Permission Management
    func requestPermissions() async {
        await notificationService.requestPermissions()
        await checkPermissions()
    }
    
    func checkPermissions() async {
        await notificationService.checkPermissions()
    }
    
    func openNotificationSettings() {
        NotificationUtilities.openNotificationSettings()
    }
    
    // MARK: - Sample Data Generation (for demo)
    private func generateSampleNotifications() async {
        guard let currentUser = authService.currentAppUser else { return }
        
        let sampleNotifications = [
            Notification(
                title: "New SIF Received",
                body: "John sent you a birthday SIF!",
                type: .sifReceived,
                payload: NotificationPayload.sifPayload(sifId: "sif_123", senderId: "user_456"),
                recipientUID: currentUser.uid,
                priority: .high,
                actions: NotificationActionFactory.actionsFor(notificationType: .sifReceived)
            ),
            Notification(
                title: "Friend Request",
                body: "Sarah wants to connect with you",
                type: .friendRequest,
                payload: NotificationPayload.friendRequestPayload(senderId: "user_789"),
                recipientUID: currentUser.uid,
                priority: .normal,
                actions: NotificationActionFactory.actionsFor(notificationType: .friendRequest)
            ),
            Notification(
                title: "SIF Delivered",
                body: "Your birthday SIF was delivered to Mom",
                type: .sifDelivered,
                recipientUID: currentUser.uid,
                priority: .normal
            ),
            Notification(
                title: "New Achievement",
                body: "You've sent 50 SIFs! Keep spreading joy!",
                type: .achievement,
                payload: NotificationPayload.achievementPayload(
                    achievementId: "achievement_50_sifs",
                    metadata: ["count": "50", "type": "sifs_sent"]
                ),
                recipientUID: currentUser.uid,
                priority: .normal
            )
        ]
        
        for notification in sampleNotifications {
            notificationService.addNotification(notification)
        }
    }
    
    // MARK: - Computed Properties
    var filteredNotificationCount: Int {
        return notifications.count
    }
    
    var hasUnreadNotifications: Bool {
        return unreadCount > 0
    }
    
    var notificationsByCategory: [NotificationCategory: [Notification]] {
        return NotificationUtilities.groupNotificationsByType(notifications)
    }
    
    var groupedNotifications: [String: [Notification]] {
        return NotificationUtilities.groupNotifications(notifications)
    }
}