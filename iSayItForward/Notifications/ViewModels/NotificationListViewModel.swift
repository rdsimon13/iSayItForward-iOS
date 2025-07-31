import Foundation
import SwiftUI
import Combine

// MARK: - Notification List View Model
class NotificationListViewModel: ObservableObject {
    
    @Published var notifications: [Notification] = []
    @Published var isLoading: Bool = false
    @Published var isRefreshing: Bool = false
    @Published var error: String?
    @Published var hasMoreToLoad: Bool = true
    @Published var selectedNotifications: Set<String> = []
    @Published var isSelectionMode: Bool = false
    
    private let notificationService = NotificationService.shared
    private var cancellables = Set<AnyCancellable>()
    private var lastDocument: Date?
    private let pageSize = 20
    
    init() {
        setupBindings()
    }
    
    // MARK: - Setup
    private func setupBindings() {
        notificationService.$notifications
            .receive(on: DispatchQueue.main)
            .assign(to: \.notifications, on: self)
            .store(in: &cancellables)
        
        notificationService.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: \.isLoading, on: self)
            .store(in: &cancellables)
        
        notificationService.$error
            .receive(on: DispatchQueue.main)
            .map { $0?.localizedDescription }
            .assign(to: \.error, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Data Loading
    func loadNotifications() {
        guard !isLoading else { return }
        
        isLoading = true
        lastDocument = nil
        hasMoreToLoad = true
        
        // Reset the list
        notifications = []
        
        // Load first page
        loadNextPage()
    }
    
    func loadNextPage() {
        guard !isLoading && hasMoreToLoad else { return }
        
        isLoading = true
        
        // In a real implementation, this would load the next page of notifications
        // For now, we'll simulate pagination
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.isLoading = false
            // Simulate no more data after first load
            self?.hasMoreToLoad = false
        }
    }
    
    func refresh() {
        guard !isRefreshing else { return }
        
        isRefreshing = true
        
        // Simulate refresh
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.isRefreshing = false
            self?.loadNotifications()
        }
    }
    
    // MARK: - Selection Management
    func toggleSelection(for notificationId: String) {
        if selectedNotifications.contains(notificationId) {
            selectedNotifications.remove(notificationId)
        } else {
            selectedNotifications.insert(notificationId)
        }
        
        // Exit selection mode if no items are selected
        if selectedNotifications.isEmpty {
            isSelectionMode = false
        }
    }
    
    func selectAll() {
        selectedNotifications = Set(notifications.compactMap { $0.id })
        isSelectionMode = true
    }
    
    func deselectAll() {
        selectedNotifications.removeAll()
        isSelectionMode = false
    }
    
    func enterSelectionMode() {
        isSelectionMode = true
    }
    
    func exitSelectionMode() {
        isSelectionMode = false
        selectedNotifications.removeAll()
    }
    
    // MARK: - Batch Actions
    func markSelectedAsRead() {
        for notificationId in selectedNotifications {
            notificationService.markAsRead(notificationId: notificationId)
        }
        exitSelectionMode()
    }
    
    func deleteSelected() {
        for notificationId in selectedNotifications {
            notificationService.deleteNotification(notificationId: notificationId)
        }
        exitSelectionMode()
    }
    
    func archiveSelected() {
        // In a real implementation, this would archive the notifications
        // For now, we'll delete them
        deleteSelected()
    }
    
    // MARK: - Individual Actions
    func markAsRead(_ notification: Notification) {
        guard let id = notification.id else { return }
        notificationService.markAsRead(notificationId: id)
    }
    
    func markAsUnread(_ notification: Notification) {
        // In a real implementation, this would mark as unread
        // For now, we'll skip this functionality
    }
    
    func deleteNotification(_ notification: Notification) {
        guard let id = notification.id else { return }
        notificationService.deleteNotification(notificationId: id)
    }
    
    func archiveNotification(_ notification: Notification) {
        // In a real implementation, this would archive the notification
        deleteNotification(notification)
    }
    
    func shareNotification(_ notification: Notification) {
        let shareText = "\(notification.title)\n\(notification.message)"
        UIPasteboard.general.string = shareText
    }
    
    func scheduleReminder(for notification: Notification, at date: Date) {
        do {
            try NotificationScheduler.shared.scheduleReminder(for: notification, at: date)
        } catch {
            self.error = "Failed to schedule reminder: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Swipe Actions
    func getLeadingSwipeActions(for notification: Notification) -> [SwipeAction] {
        var actions: [SwipeAction] = []
        
        if !notification.isRead {
            actions.append(SwipeAction(
                title: "Read",
                iconName: "checkmark",
                backgroundColor: .green,
                action: { [weak self] in
                    self?.markAsRead(notification)
                }
            ))
        }
        
        actions.append(SwipeAction(
            title: "Archive",
            iconName: "archivebox",
            backgroundColor: .blue,
            action: { [weak self] in
                self?.archiveNotification(notification)
            }
        ))
        
        return actions
    }
    
    func getTrailingSwipeActions(for notification: Notification) -> [SwipeAction] {
        var actions: [SwipeAction] = []
        
        actions.append(SwipeAction(
            title: "Share",
            iconName: "square.and.arrow.up",
            backgroundColor: .indigo,
            action: { [weak self] in
                self?.shareNotification(notification)
            }
        ))
        
        actions.append(SwipeAction(
            title: "Delete",
            iconName: "trash",
            backgroundColor: .red,
            action: { [weak self] in
                self?.deleteNotification(notification)
            }
        ))
        
        return actions
    }
    
    // MARK: - Filtering and Sorting
    func filterNotifications(by predicate: (Notification) -> Bool) -> [Notification] {
        return notifications.filter(predicate)
    }
    
    func sortNotifications(by keyPath: KeyPath<Notification, Date>, ascending: Bool = false) -> [Notification] {
        return notifications.sorted { notification1, notification2 in
            let date1 = notification1[keyPath: keyPath]
            let date2 = notification2[keyPath: keyPath]
            return ascending ? date1 < date2 : date1 > date2
        }
    }
    
    // MARK: - Statistics
    var selectedCount: Int {
        return selectedNotifications.count
    }
    
    var unreadCount: Int {
        return notifications.filter { !$0.isRead }.count
    }
    
    var totalCount: Int {
        return notifications.count
    }
    
    var hasUnreadNotifications: Bool {
        return unreadCount > 0
    }
    
    var canLoadMore: Bool {
        return hasMoreToLoad && !isLoading
    }
    
    // MARK: - Helper Methods
    func isSelected(_ notificationId: String) -> Bool {
        return selectedNotifications.contains(notificationId)
    }
    
    func shouldShowLoadingIndicator(for index: Int) -> Bool {
        // Show loading indicator when approaching the end of the list
        return index >= notifications.count - 3 && hasMoreToLoad && !isLoading
    }
    
    func getNotification(by id: String) -> Notification? {
        return notifications.first { $0.id == id }
    }
    
    func getNotificationIndex(by id: String) -> Int? {
        return notifications.firstIndex { $0.id == id }
    }
}

// MARK: - Swipe Action Model
struct SwipeAction {
    let title: String
    let iconName: String
    let backgroundColor: Color
    let action: () -> Void
    
    var systemImage: String {
        return iconName
    }
}

// MARK: - List Display Modes
enum NotificationListDisplayMode {
    case compact
    case expanded
    case card
    
    var cellHeight: CGFloat {
        switch self {
        case .compact: return 60
        case .expanded: return 100
        case .card: return 120
        }
    }
    
    var showsFullMessage: Bool {
        switch self {
        case .compact: return false
        case .expanded, .card: return true
        }
    }
    
    var showsActions: Bool {
        switch self {
        case .compact: return false
        case .expanded, .card: return true
        }
    }
}