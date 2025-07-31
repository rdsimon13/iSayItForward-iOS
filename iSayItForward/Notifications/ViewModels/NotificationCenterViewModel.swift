import Foundation
import SwiftUI
import Combine
import FirebaseAuth

// MARK: - Notification Center View Model
class NotificationCenterViewModel: ObservableObject {
    
    @Published var notifications: [Notification] = []
    @Published var filteredNotifications: [Notification] = []
    @Published var groupedNotifications: [NotificationGroup] = []
    @Published var selectedFilter: NotificationFilter = .all
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var showingClearAllAlert: Bool = false
    @Published var unreadCount: Int = 0
    
    private let notificationService = NotificationService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
        loadNotifications()
    }
    
    // MARK: - Setup
    private func setupBindings() {
        // Bind to notification service
        notificationService.$notifications
            .receive(on: DispatchQueue.main)
            .assign(to: \.notifications, on: self)
            .store(in: &cancellables)
        
        notificationService.$unreadCount
            .receive(on: DispatchQueue.main)
            .assign(to: \.unreadCount, on: self)
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
        
        // Filter notifications when search text or filter changes
        Publishers.CombineLatest3($notifications, $selectedFilter, $searchText)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .map { [weak self] notifications, filter, searchText in
                self?.filterNotifications(notifications, filter: filter, searchText: searchText) ?? []
            }
            .assign(to: \.filteredNotifications, on: self)
            .store(in: &cancellables)
        
        // Group filtered notifications
        $filteredNotifications
            .map { [weak self] notifications in
                self?.groupNotifications(notifications) ?? []
            }
            .assign(to: \.groupedNotifications, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Data Loading
    func loadNotifications() {
        // The service automatically loads notifications when user is authenticated
        // This method can be used for manual refresh
        refresh()
    }
    
    func refresh() {
        // Refresh notifications from service
        // In a real implementation, this would trigger a reload from the service
        notificationService.loadNotifications(for: getCurrentUserId())
    }
    
    private func getCurrentUserId() -> String {
        return notificationService.getCurrentUserId()
    }
    
    // MARK: - Filtering
    private func filterNotifications(_ notifications: [Notification], filter: NotificationFilter, searchText: String) -> [Notification] {
        var filtered = notifications
        
        // Apply category/type filter
        switch filter {
        case .all:
            break
        case .unread:
            filtered = filtered.filter { !$0.isRead }
        case .category(let category):
            filtered = filtered.filter { $0.type.category == category }
        case .type(let type):
            filtered = filtered.filter { $0.type == type }
        case .priority(let priority):
            filtered = filtered.filter { $0.priority == priority }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { notification in
                notification.title.localizedCaseInsensitiveContains(searchText) ||
                notification.message.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered
    }
    
    // MARK: - Grouping
    private func groupNotifications(_ notifications: [Notification]) -> [NotificationGroup] {
        let calendar = Calendar.current
        let now = Date()
        
        // Group by date ranges
        let groups = Dictionary(grouping: notifications) { notification in
            let date = notification.createdDate
            
            if calendar.isDateInToday(date) {
                return "Today"
            } else if calendar.isDateInYesterday(date) {
                return "Yesterday"
            } else if date.timeIntervalSinceNow > -604800 { // Within a week
                let formatter = DateFormatter()
                formatter.dateFormat = "EEEE"
                return formatter.string(from: date)
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d, yyyy"
                return formatter.string(from: date)
            }
        }
        
        // Convert to NotificationGroup objects and sort
        let notificationGroups = groups.map { key, notifications in
            NotificationGroup(
                title: key,
                notifications: notifications.sorted { $0.createdDate > $1.createdDate }
            )
        }
        
        // Sort groups by date
        return notificationGroups.sorted { group1, group2 in
            // Get the most recent notification from each group to determine order
            let date1 = group1.notifications.first?.createdDate ?? Date.distantPast
            let date2 = group2.notifications.first?.createdDate ?? Date.distantPast
            return date1 > date2
        }
    }
    
    // MARK: - Actions
    func markAsRead(_ notification: Notification) {
        guard let id = notification.id else { return }
        notificationService.markAsRead(notificationId: id)
    }
    
    func markAllAsRead() {
        notificationService.markAllAsRead(for: getCurrentUserId())
    }
    
    func deleteNotification(_ notification: Notification) {
        guard let id = notification.id else { return }
        notificationService.deleteNotification(notificationId: id)
    }
    
    func clearAllNotifications() {
        showingClearAllAlert = true
    }
    
    func confirmClearAll() {
        let notificationIds = notifications.compactMap { $0.id }
        for id in notificationIds {
            notificationService.deleteNotification(notificationId: id)
        }
        showingClearAllAlert = false
    }
    
    func archiveNotification(_ notification: Notification) {
        // In a real implementation, this would mark the notification as archived
        deleteNotification(notification)
    }
    
    func shareNotification(_ notification: Notification) {
        // Implementation would depend on the sharing mechanism
        // For now, we'll just copy the text to clipboard
        let shareText = "\(notification.title)\n\(notification.message)"
        UIPasteboard.general.string = shareText
    }
    
    // MARK: - Filter Management
    func setFilter(_ filter: NotificationFilter) {
        selectedFilter = filter
    }
    
    func clearFilter() {
        selectedFilter = .all
        searchText = ""
    }
    
    // MARK: - Search
    func searchNotifications(query: String) {
        searchText = query
    }
    
    func clearSearch() {
        searchText = ""
    }
    
    // MARK: - Statistics
    var totalNotifications: Int {
        return notifications.count
    }
    
    var unreadNotifications: Int {
        return notifications.filter { !$0.isRead }.count
    }
    
    var notificationsByCategory: [NotificationCategory: Int] {
        let categories = notifications.map { $0.type.category }
        return Dictionary(grouping: categories) { $0 }.mapValues { $0.count }
    }
    
    var notificationsByType: [NotificationType: Int] {
        let types = notifications.map { $0.type }
        return Dictionary(grouping: types) { $0 }.mapValues { $0.count }
    }
}

// MARK: - Notification Group Model
struct NotificationGroup: Identifiable {
    let id = UUID()
    let title: String
    let notifications: [Notification]
    
    var unreadCount: Int {
        return notifications.filter { !$0.isRead }.count
    }
    
    var totalCount: Int {
        return notifications.count
    }
    
    var hasUnread: Bool {
        return unreadCount > 0
    }
}

// MARK: - Notification Filter
enum NotificationFilter: Equatable, CaseIterable {
    case all
    case unread
    case category(NotificationCategory)
    case type(NotificationType)
    case priority(NotificationPriority)
    
    static var allCases: [NotificationFilter] {
        var cases: [NotificationFilter] = [.all, .unread]
        
        // Add category filters
        cases.append(contentsOf: NotificationCategory.allCases.map { .category($0) })
        
        // Add priority filters
        cases.append(contentsOf: NotificationPriority.allCases.map { .priority($0) })
        
        return cases
    }
    
    var displayName: String {
        switch self {
        case .all:
            return "All"
        case .unread:
            return "Unread"
        case .category(let category):
            return category.displayName
        case .type(let type):
            return type.displayName
        case .priority(let priority):
            return priority.displayName
        }
    }
    
    var iconName: String {
        switch self {
        case .all:
            return "tray.fill"
        case .unread:
            return "envelope.badge"
        case .category(let category):
            return category.iconName
        case .type(let type):
            return type.iconName
        case .priority(let priority):
            switch priority {
            case .low: return "arrow.down.circle"
            case .normal: return "circle"
            case .high: return "arrow.up.circle"
            case .urgent: return "exclamationmark.circle"
            }
        }
    }
}

// MARK: - Extension for NotificationService Integration
extension NotificationService {
    func getCurrentUserId() -> String {
        return Auth.auth().currentUser?.uid ?? ""
    }
    
    func loadNotifications(for userId: String) {
        // This method already exists in NotificationService
        // Just ensuring it's accessible from the view model
    }
}