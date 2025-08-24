import SwiftUI

// MARK: - Notification Detail View
struct NotificationDetailView: View {
    let notification: Notification
    @StateObject private var actionViewModel = NotificationActionViewModel()
    @Environment(\.presentationMode) var presentationMode
    @State private var showingReplySheet = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                NotificationDetailHeader(notification: notification)
                
                // Content
                NotificationDetailContent(notification: notification)
                
                // Payload Information
                if let payload = notification.payload {
                    NotificationPayloadView(payload: payload)
                }
                
                // Actions
                if !notification.actions.isEmpty {
                    NotificationDetailActions(
                        actions: notification.actions,
                        actionViewModel: actionViewModel,
                        notification: notification
                    )
                }
                
                // Related Content
                NotificationRelatedContent(notification: notification)
                
                Spacer(minLength: 100)
            }
            .padding()
        }
        .background(Color.mainAppGradient.ignoresSafeArea())
        .navigationTitle("Notification")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    NotificationDetailMenu(
                        notification: notification,
                        actionViewModel: actionViewModel
                    )
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.brandDarkBlue)
                }
            }
        }
        .sheet(isPresented: $showingReplySheet) {
            NotificationReplyView(
                notification: notification,
                actionViewModel: actionViewModel
            )
        }
        .onAppear {
            // Mark as read when viewed
            if !notification.isRead {
                NotificationService.shared.markAsRead(notification.id)
            }
        }
    }
}

// MARK: - Detail Header
private struct NotificationDetailHeader: View {
    let notification: Notification
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                NotificationBadgeView(
                    type: notification.type,
                    priority: notification.priority,
                    isRead: notification.isRead
                )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(notification.type.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text(notification.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(NotificationUtilities.formatNotificationDate(notification.createdAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    NotificationStateBadgeView(state: notification.state)
                }
            }
            
            if notification.priority == .high || notification.priority == .critical {
                NotificationPriorityBadgeView(priority: notification.priority)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.9))
                .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
        )
    }
}

// MARK: - Detail Content
private struct NotificationDetailContent: View {
    let notification: Notification
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Message")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.brandDarkBlue)
            
            Text(notification.body)
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
            
            if let scheduledAt = notification.scheduledAt {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Scheduled For")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text(NotificationUtilities.formatNotificationDate(scheduledAt))
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.9))
                .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
        )
    }
}

// MARK: - Payload View
private struct NotificationPayloadView: View {
    let payload: NotificationPayload
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.brandDarkBlue)
            
            VStack(alignment: .leading, spacing: 8) {
                if let sifId = payload.sifId {
                    DetailRow(label: "SIF ID", value: sifId)
                }
                
                if let senderId = payload.senderId {
                    DetailRow(label: "Sender", value: senderId)
                }
                
                if let templateId = payload.templateId {
                    DetailRow(label: "Template", value: templateId)
                }
                
                if let chatId = payload.chatId {
                    DetailRow(label: "Chat", value: chatId)
                }
                
                if let deepLink = payload.deepLink {
                    DetailRow(label: "Deep Link", value: deepLink)
                }
                
                if let metadata = payload.metadata {
                    ForEach(Array(metadata.keys.sorted()), id: \.self) { key in
                        DetailRow(label: key.capitalized, value: metadata[key] ?? "")
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.9))
                .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
        )
    }
}

// MARK: - Detail Row
private struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(nil)
            
            Spacer()
        }
    }
}

// MARK: - Detail Actions
private struct NotificationDetailActions: View {
    let actions: [NotificationAction]
    @ObservedObject var actionViewModel: NotificationActionViewModel
    let notification: Notification
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Actions")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.brandDarkBlue)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(actions) { action in
                    ActionButton(
                        action: action,
                        isLoading: actionViewModel.isPerformingAction,
                        onTap: {
                            Task {
                                await actionViewModel.performAction(action, for: notification)
                            }
                        }
                    )
                }
            }
            
            if let result = actionViewModel.lastActionResult {
                ActionResultView(result: result)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.9))
                .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
        )
    }
}

// MARK: - Action Button
private struct ActionButton: View {
    let action: NotificationAction
    let isLoading: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: action.iconName)
                        .font(.system(size: 16, weight: .medium))
                }
                
                Text(action.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(buttonTextColor)
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(buttonBackgroundColor)
            )
        }
        .disabled(isLoading)
    }
    
    private var buttonTextColor: Color {
        switch action.style {
        case .primary: return .white
        case .destructive: return .white
        case .default: return .brandDarkBlue
        case .cancel: return .gray
        }
    }
    
    private var buttonBackgroundColor: Color {
        switch action.style {
        case .primary: return .brandDarkBlue
        case .destructive: return .red
        case .default: return .brandDarkBlue.opacity(0.1)
        case .cancel: return .gray.opacity(0.1)
        }
    }
}

// MARK: - Action Result View
private struct ActionResultView: View {
    let result: NotificationActionViewModel.ActionResult
    
    var body: some View {
        HStack {
            Image(systemName: result.isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(result.isSuccess ? .green : .red)
            
            Text(result.message)
                .font(.caption)
                .foregroundColor(result.isSuccess ? .green : .red)
            
            Spacer()
        }
        .padding(.top, 8)
    }
}

// MARK: - Related Content
private struct NotificationRelatedContent: View {
    let notification: Notification
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Related")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.brandDarkBlue)
            
            // Quick links based on notification type
            switch notification.type {
            case .sifReceived, .sifDelivered:
                QuickLinkCard(
                    title: "My SIFs",
                    subtitle: "View all your SIFs",
                    icon: "envelope.fill",
                    color: .brandDarkBlue
                )
                
            case .friendRequest, .friendAccepted:
                QuickLinkCard(
                    title: "Friends",
                    subtitle: "Manage your connections",
                    icon: "person.2.fill",
                    color: .green
                )
                
            case .templateShared, .templateUpdated:
                QuickLinkCard(
                    title: "Template Gallery",
                    subtitle: "Browse templates",
                    icon: "doc.on.doc.fill",
                    color: .purple
                )
                
            default:
                QuickLinkCard(
                    title: "Settings",
                    subtitle: "Manage notifications",
                    icon: "gear.circle.fill",
                    color: .gray
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.9))
                .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
        )
    }
}

// MARK: - Quick Link Card
private struct QuickLinkCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Detail Menu
private struct NotificationDetailMenu: View {
    let notification: Notification
    @ObservedObject var actionViewModel: NotificationActionViewModel
    
    var body: some View {
        Group {
            if !notification.isRead {
                Button {
                    Task {
                        await actionViewModel.performAction(.view, for: notification)
                    }
                } label: {
                    Label("Mark as Read", systemImage: "envelope.open")
                }
            }
            
            Button {
                Task {
                    await actionViewModel.performAction(.archive, for: notification)
                }
            } label: {
                Label("Archive", systemImage: "archivebox")
            }
            
            Button {
                Task {
                    await actionViewModel.performAction(.share, for: notification)
                }
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            
            Divider()
            
            Button(role: .destructive) {
                Task {
                    await actionViewModel.performAction(.delete, for: notification)
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Preview
struct NotificationDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleNotification = Notification(
            title: "New SIF Received",
            body: "John sent you a birthday SIF! Tap to view the message and respond.",
            type: .sifReceived,
            payload: NotificationPayload.sifPayload(sifId: "sif_123", senderId: "user_456"),
            recipientUID: "current_user",
            priority: .high,
            actions: NotificationActionFactory.actionsFor(notificationType: .sifReceived)
        )
        
        NavigationView {
            NotificationDetailView(notification: sampleNotification)
        }
    }
}