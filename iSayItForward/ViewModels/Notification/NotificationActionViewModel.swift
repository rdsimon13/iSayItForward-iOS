import Foundation
import Combine
import SwiftUI

// MARK: - Notification Action ViewModel
@MainActor
class NotificationActionViewModel: ObservableObject {
    @Published var isPerformingAction: Bool = false
    @Published var lastActionResult: ActionResult?
    @Published var showingActionSheet: Bool = false
    @Published var showingReplySheet: Bool = false
    @Published var replyText: String = ""
    
    private let notificationService = NotificationService.shared
    private let authService = AuthenticationService.shared
    
    // MARK: - Action Result
    enum ActionResult {
        case success(String)
        case failure(String)
        case cancelled
        
        var isSuccess: Bool {
            switch self {
            case .success:
                return true
            default:
                return false
            }
        }
        
        var message: String {
            switch self {
            case .success(let message):
                return message
            case .failure(let message):
                return message
            case .cancelled:
                return "Action cancelled"
            }
        }
    }
    
    // MARK: - Action Execution
    func performAction(_ action: NotificationAction, for notification: Notification) async {
        isPerformingAction = true
        lastActionResult = nil
        
        do {
            switch action.type {
            case .reply:
                await handleReplyAction(notification)
            case .accept:
                await handleAcceptAction(notification)
            case .decline:
                await handleDeclineAction(notification)
            case .view:
                await handleViewAction(notification)
            case .delete:
                await handleDeleteAction(notification)
            case .archive:
                await handleArchiveAction(notification)
            case .share:
                await handleShareAction(notification)
            case .remind:
                await handleRemindAction(notification)
            case .openSIF:
                await handleOpenSIFAction(notification)
            case .openProfile:
                await handleOpenProfileAction(notification)
            case .openChat:
                await handleOpenChatAction(notification)
            case .openTemplate:
                await handleOpenTemplateAction(notification)
            case .dismiss:
                await handleDismissAction(notification)
            }
        } catch {
            lastActionResult = .failure("Action failed: \(error.localizedDescription)")
        }
        
        isPerformingAction = false
    }
    
    // MARK: - Action Handlers
    private func handleReplyAction(_ notification: Notification) async {
        showingReplySheet = true
    }
    
    func sendReply(to notification: Notification) async {
        guard !replyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            lastActionResult = .failure("Reply message cannot be empty")
            return
        }
        
        // Simulate sending reply
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Mark notification as read
        notificationService.markAsRead(notification.id)
        
        // Create response notification (simulate)
        if let payload = notification.payload, let senderId = payload.senderId {
            await createResponseNotification(
                title: "Reply Sent",
                body: "Your reply was sent successfully",
                originalNotification: notification
            )
        }
        
        lastActionResult = .success("Reply sent successfully")
        replyText = ""
        showingReplySheet = false
    }
    
    private func handleAcceptAction(_ notification: Notification) async {
        // Simulate API call
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        switch notification.type {
        case .friendRequest:
            await handleFriendRequestAccept(notification)
        default:
            lastActionResult = .success("Request accepted")
        }
        
        // Mark as read and archive
        notificationService.markAsRead(notification.id)
        notificationService.archiveNotification(notification.id)
    }
    
    private func handleDeclineAction(_ notification: Notification) async {
        // Simulate API call
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        switch notification.type {
        case .friendRequest:
            await handleFriendRequestDecline(notification)
        default:
            lastActionResult = .success("Request declined")
        }
        
        // Mark as read and archive
        notificationService.markAsRead(notification.id)
        notificationService.archiveNotification(notification.id)
    }
    
    private func handleViewAction(_ notification: Notification) async {
        // Mark as read
        notificationService.markAsRead(notification.id)
        
        // Navigate to content
        if let payload = notification.payload, let deepLink = payload.deepLink {
            handleDeepLink(deepLink)
        }
        
        lastActionResult = .success("Opened content")
    }
    
    private func handleDeleteAction(_ notification: Notification) async {
        notificationService.deleteNotification(notification.id)
        lastActionResult = .success("Notification deleted")
    }
    
    private func handleArchiveAction(_ notification: Notification) async {
        notificationService.archiveNotification(notification.id)
        lastActionResult = .success("Notification archived")
    }
    
    private func handleShareAction(_ notification: Notification) async {
        // Simulate sharing
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        // In a real app, this would open the system share sheet
        print("Sharing notification: \(notification.title)")
        
        lastActionResult = .success("Shared successfully")
    }
    
    private func handleRemindAction(_ notification: Notification) async {
        // Create reminder notification
        guard let currentUser = authService.currentAppUser else {
            lastActionResult = .failure("User not authenticated")
            return
        }
        
        let reminderNotification = Notification(
            title: "Reminder: \(notification.title)",
            body: "Don't forget: \(notification.body)",
            type: .sifReminder,
            scheduledAt: Calendar.current.date(byAdding: .hour, value: 1, to: Date()),
            recipientUID: currentUser.uid,
            priority: .normal
        )
        
        notificationService.addNotification(reminderNotification)
        lastActionResult = .success("Reminder set for 1 hour")
    }
    
    private func handleOpenSIFAction(_ notification: Notification) async {
        guard let payload = notification.payload, let sifId = payload.sifId else {
            lastActionResult = .failure("SIF not found")
            return
        }
        
        // Mark as read
        notificationService.markAsRead(notification.id)
        
        // Navigate to SIF
        let deepLink = NotificationConstants.DeepLinks.sifURL(id: sifId)
        handleDeepLink(deepLink)
        
        lastActionResult = .success("Opened SIF")
    }
    
    private func handleOpenProfileAction(_ notification: Notification) async {
        guard let payload = notification.payload, let senderId = payload.senderId else {
            lastActionResult = .failure("Profile not found")
            return
        }
        
        // Mark as read
        notificationService.markAsRead(notification.id)
        
        // Navigate to profile
        let deepLink = NotificationConstants.DeepLinks.profileURL(userID: senderId)
        handleDeepLink(deepLink)
        
        lastActionResult = .success("Opened profile")
    }
    
    private func handleOpenChatAction(_ notification: Notification) async {
        guard let payload = notification.payload, let chatId = payload.chatId else {
            lastActionResult = .failure("Chat not found")
            return
        }
        
        // Mark as read
        notificationService.markAsRead(notification.id)
        
        // Navigate to chat
        let deepLink = NotificationConstants.DeepLinks.chatURL(chatID: chatId)
        handleDeepLink(deepLink)
        
        lastActionResult = .success("Opened chat")
    }
    
    private func handleOpenTemplateAction(_ notification: Notification) async {
        guard let payload = notification.payload, let templateId = payload.templateId else {
            lastActionResult = .failure("Template not found")
            return
        }
        
        // Mark as read
        notificationService.markAsRead(notification.id)
        
        // Navigate to template
        let deepLink = NotificationConstants.DeepLinks.templateURL(templateID: templateId)
        handleDeepLink(deepLink)
        
        lastActionResult = .success("Opened template")
    }
    
    private func handleDismissAction(_ notification: Notification) async {
        notificationService.markAsRead(notification.id)
        lastActionResult = .success("Notification dismissed")
    }
    
    // MARK: - Specialized Handlers
    private func handleFriendRequestAccept(_ notification: Notification) async {
        guard let payload = notification.payload, let senderId = payload.senderId else {
            lastActionResult = .failure("Invalid friend request")
            return
        }
        
        // Simulate accepting friend request
        print("Accepting friend request from user: \(senderId)")
        
        // Create success notification
        await createResponseNotification(
            title: "Friend Request Accepted",
            body: "You are now friends!",
            originalNotification: notification
        )
        
        lastActionResult = .success("Friend request accepted")
    }
    
    private func handleFriendRequestDecline(_ notification: Notification) async {
        guard let payload = notification.payload, let senderId = payload.senderId else {
            lastActionResult = .failure("Invalid friend request")
            return
        }
        
        // Simulate declining friend request
        print("Declining friend request from user: \(senderId)")
        
        lastActionResult = .success("Friend request declined")
    }
    
    // MARK: - Helper Methods
    private func handleDeepLink(_ deepLink: String) {
        // Post notification for app-level deep link handling
        NotificationCenter.default.post(
            name: .handleDeepLink,
            object: deepLink
        )
    }
    
    private func createResponseNotification(title: String, body: String, originalNotification: Notification) async {
        guard let currentUser = authService.currentAppUser else { return }
        
        let responseNotification = Notification(
            title: title,
            body: body,
            type: .systemUpdate,
            recipientUID: currentUser.uid,
            priority: .low
        )
        
        notificationService.addNotification(responseNotification)
    }
    
    // MARK: - Bulk Actions
    func performBulkAction(_ actionType: ActionType, notifications: [Notification]) async {
        isPerformingAction = true
        
        var successCount = 0
        var failureCount = 0
        
        for notification in notifications {
            do {
                switch actionType {
                case .delete:
                    notificationService.deleteNotification(notification.id)
                case .archive:
                    notificationService.archiveNotification(notification.id)
                case .view:
                    notificationService.markAsRead(notification.id)
                default:
                    continue
                }
                successCount += 1
            } catch {
                failureCount += 1
            }
        }
        
        if failureCount == 0 {
            lastActionResult = .success("Successfully processed \(successCount) notifications")
        } else {
            lastActionResult = .failure("Processed \(successCount) notifications, \(failureCount) failed")
        }
        
        isPerformingAction = false
    }
    
    // MARK: - Validation
    func canPerformAction(_ action: NotificationAction, for notification: Notification) -> Bool {
        switch action.type {
        case .reply:
            return notification.type == .messageReceived || notification.type == .sifReceived
        case .accept, .decline:
            return notification.type == .friendRequest
        case .openSIF:
            return notification.payload?.sifId != nil
        case .openProfile:
            return notification.payload?.senderId != nil
        case .openChat:
            return notification.payload?.chatId != nil
        case .openTemplate:
            return notification.payload?.templateId != nil
        case .archive:
            return notification.state.canArchive
        default:
            return true
        }
    }
}