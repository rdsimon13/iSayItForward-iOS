import Foundation
import SwiftUI
import Combine

// MARK: - Notification Detail View Model
class NotificationDetailViewModel: ObservableObject {
    
    @Published var notification: Notification?
    @Published var relatedNotifications: [Notification] = []
    @Published var availableActions: [NotificationAction] = []
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var showingActionSheet: Bool = false
    @Published var showingDeleteConfirmation: Bool = false
    @Published var showingReminderSheet: Bool = false
    
    private let notificationService = NotificationService.shared
    private let scheduler = NotificationScheduler.shared
    private var cancellables = Set<AnyCancellable>()
    
    init(notificationId: String) {
        loadNotification(id: notificationId)
        setupBindings()
    }
    
    init(notification: Notification) {
        self.notification = notification
        setupBindings()
        loadRelatedContent()
        setupActions()
        
        // Mark as read when viewed
        markAsReadIfNeeded()
    }
    
    // MARK: - Setup
    private func setupBindings() {
        notificationService.$error
            .receive(on: DispatchQueue.main)
            .map { $0?.localizedDescription }
            .assign(to: \.error, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Data Loading
    private func loadNotification(id: String) {
        isLoading = true
        
        // In a real implementation, this would load the specific notification from Firestore
        if let existingNotification = notificationService.notifications.first(where: { $0.id == id }) {
            self.notification = existingNotification
            loadRelatedContent()
            setupActions()
            markAsReadIfNeeded()
        }
        
        isLoading = false
    }
    
    private func loadRelatedContent() {
        guard let notification = notification else { return }
        
        // Load related notifications based on groupId or relatedSIFId
        var related: [Notification] = []
        
        if let groupId = notification.groupId {
            related = notificationService.notifications.filter { 
                $0.groupId == groupId && $0.id != notification.id 
            }
        } else if let sifId = notification.relatedSIFId {
            related = notificationService.notifications.filter {
                $0.relatedSIFId == sifId && $0.id != notification.id
            }
        }
        
        self.relatedNotifications = related.sorted { $0.createdDate > $1.createdDate }
    }
    
    private func setupActions() {
        guard let notification = notification else { return }
        
        var actions: [NotificationAction] = []
        
        // Always available actions
        if !notification.isRead {
            actions.append(.markAsRead)
        }
        
        actions.append(.share)
        actions.append(.delete)
        
        // Type-specific actions
        switch notification.type {
        case .messageResponse, .mention:
            actions.insert(.reply, at: 0)
            if let sifId = notification.relatedSIFId {
                actions.append(.openSIF(sifId: sifId))
            }
            
        case .sifReceived:
            if let sifId = notification.relatedSIFId {
                actions.insert(.openSIF(sifId: sifId), at: 0)
            }
            actions.append(.reply)
            
        case .impactMilestone:
            actions.insert(.view, at: 0)
            
        case .reminderScheduled:
            // For reminders, we might want to reschedule
            break
            
        default:
            actions.insert(.view, at: 0)
        }
        
        // Schedule reminder action for all notifications
        let reminderAction = NotificationAction(
            title: "Remind Me",
            type: .scheduleReminder,
            style: .default
        )
        actions.append(reminderAction)
        
        self.availableActions = actions
    }
    
    // MARK: - Actions
    func markAsRead() {
        guard let notification = notification, let id = notification.id else { return }
        
        notificationService.markAsRead(notificationId: id)
        
        // Update local state
        self.notification?.isRead = true
    }
    
    private func markAsReadIfNeeded() {
        guard let notification = notification, !notification.isRead else { return }
        
        // Automatically mark as read when viewing the detail
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.markAsRead()
        }
    }
    
    func deleteNotification() {
        guard let notification = notification, let id = notification.id else { return }
        
        notificationService.deleteNotification(notificationId: id)
        
        // Navigate back or close the detail view
        NotificationCenter.default.post(name: .notificationDeleted, object: id)
    }
    
    func shareNotification() {
        guard let notification = notification else { return }
        
        let shareText = formatShareText(notification)
        let activityController = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )
        
        // Present the share sheet
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            rootViewController.present(activityController, animated: true)
        }
    }
    
    func performAction(_ action: NotificationAction) {
        guard let notification = notification else { return }
        
        switch action.type {
        case .reply:
            handleReplyAction()
            
        case .view:
            handleViewAction()
            
        case .markAsRead:
            markAsRead()
            
        case .delete:
            showingDeleteConfirmation = true
            
        case .share:
            shareNotification()
            
        case .openSIF:
            handleOpenSIFAction()
            
        case .openProfile:
            handleOpenProfileAction()
            
        case .scheduleReminder:
            showingReminderSheet = true
            
        case .navigateToScreen:
            handleNavigationAction(action)
            
        case .openURL:
            handleOpenURLAction(action)
            
        default:
            handleCustomAction(action)
        }
    }
    
    // MARK: - Action Handlers
    private func handleReplyAction() {
        guard let notification = notification else { return }
        
        if let sifId = notification.relatedSIFId {
            // Navigate to reply screen with SIF context
            NotificationCenter.default.post(
                name: .navigateToReply,
                object: ["sifId": sifId, "notificationId": notification.id ?? ""]
            )
        } else {
            // Generic reply handling
            NotificationCenter.default.post(
                name: .showReplyComposer,
                object: notification
            )
        }
    }
    
    private func handleViewAction() {
        guard let notification = notification else { return }
        
        if let deepLinkURL = notification.deepLinkURL, let url = URL(string: deepLinkURL) {
            // Handle deep link
            NotificationCenter.default.post(name: .handleDeepLink, object: url)
        } else {
            // Default view action
            NotificationCenter.default.post(name: .viewNotificationContent, object: notification)
        }
    }
    
    private func handleOpenSIFAction() {
        guard let notification = notification,
              let sifId = notification.relatedSIFId else { return }
        
        // Navigate to SIF detail
        NotificationCenter.default.post(
            name: .navigateToSIF,
            object: sifId
        )
    }
    
    private func handleOpenProfileAction() {
        // Extract user ID from action data or notification content
        // For now, we'll use a placeholder
        NotificationCenter.default.post(
            name: .navigateToProfile,
            object: "userId"
        )
    }
    
    private func handleNavigationAction(_ action: NotificationAction) {
        guard let screenName = action.data?["screenName"] else { return }
        
        NotificationCenter.default.post(
            name: .navigateToScreen,
            object: screenName
        )
    }
    
    private func handleOpenURLAction(_ action: NotificationAction) {
        guard let urlString = action.data?["url"],
              let url = URL(string: urlString) else { return }
        
        UIApplication.shared.open(url)
    }
    
    private func handleCustomAction(_ action: NotificationAction) {
        // Handle custom actions based on the action data
        NotificationCenter.default.post(
            name: .handleCustomNotificationAction,
            object: ["action": action, "notification": notification as Any]
        )
    }
    
    // MARK: - Reminder Scheduling
    func scheduleReminder(at date: Date, customMessage: String? = nil) {
        guard let notification = notification else { return }
        
        do {
            try scheduler.scheduleReminder(
                for: notification,
                at: date,
                customMessage: customMessage
            )
            showingReminderSheet = false
        } catch {
            self.error = "Failed to schedule reminder: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Utility Methods
    private func formatShareText(_ notification: Notification) -> String {
        let title = notification.title
        let message = notification.message
        let date = NotificationFormatter.formatFullDateTime(from: notification.createdDate)
        
        return """
        \(title)
        
        \(message)
        
        Received: \(date)
        
        Shared from iSayItForward
        """
    }
    
    func getFormattedDate() -> String {
        guard let notification = notification else { return "" }
        return NotificationFormatter.formatFullDateTime(from: notification.createdDate)
    }
    
    func getFormattedRelativeTime() -> String {
        guard let notification = notification else { return "" }
        return NotificationFormatter.formatTime(from: notification.createdDate)
    }
    
    func getTypeDisplayInfo() -> (name: String, icon: String, color: Color) {
        guard let notification = notification else {
            return ("Unknown", "questionmark", .gray)
        }
        
        return (
            notification.type.displayName,
            notification.type.iconName,
            Color(notification.type.color)
        )
    }
    
    func shouldShowRelatedNotifications() -> Bool {
        return !relatedNotifications.isEmpty
    }
    
    func getActionButtonStyle(for action: NotificationAction) -> ButtonStyle {
        switch action.style {
        case .primary:
            return PrimaryActionButtonStyle()
        case .destructive:
            return DestructiveActionButtonStyle()
        case .cancel:
            return CancelActionButtonStyle()
        case .default:
            return SecondaryActionButtonStyle()
        }
    }
}

// MARK: - Button Styles (placeholder implementations)
struct DestructiveActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding()
            .background(Color.red)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct CancelActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.primary)
            .padding()
            .background(Color.secondary.opacity(0.2))
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

// MARK: - Notification Names
extension Foundation.Notification.Name {
    static let notificationDeleted = Foundation.Notification.Name("notificationDeleted")
    static let navigateToReply = Foundation.Notification.Name("navigateToReply")
    static let showReplyComposer = Foundation.Notification.Name("showReplyComposer")
    static let viewNotificationContent = Foundation.Notification.Name("viewNotificationContent")
    static let navigateToSIF = Foundation.Notification.Name("navigateToSIF")
    static let navigateToProfile = Foundation.Notification.Name("navigateToProfile")
    static let navigateToScreen = Foundation.Notification.Name("navigateToScreen")
    static let handleCustomNotificationAction = Foundation.Notification.Name("handleCustomNotificationAction")
}