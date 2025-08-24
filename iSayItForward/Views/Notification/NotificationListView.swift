import SwiftUI

// MARK: - Notification List View
struct NotificationListView: View {
    @ObservedObject var viewModel: NotificationCenterViewModel
    @ObservedObject var actionViewModel: NotificationActionViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(viewModel.groupedNotifications.keys.sorted(by: sortGroupKeys)), id: \.self) { groupKey in
                    Section {
                        ForEach(viewModel.groupedNotifications[groupKey] ?? []) { notification in
                            NotificationRowView(
                                notification: notification,
                                isSelected: viewModel.selectedNotifications.contains(notification.id),
                                isSelectionMode: viewModel.isSelectionMode,
                                onTap: {
                                    if viewModel.isSelectionMode {
                                        viewModel.toggleNotificationSelection(notification.id)
                                    } else {
                                        viewModel.handleNotificationTap(notification)
                                    }
                                },
                                onLongPress: {
                                    if !viewModel.isSelectionMode {
                                        viewModel.enterSelectionMode()
                                        viewModel.toggleNotificationSelection(notification.id)
                                    }
                                },
                                onAction: { action in
                                    Task {
                                        await actionViewModel.performAction(action, for: notification)
                                    }
                                }
                            )
                            .padding(.horizontal)
                            
                            if notification.id != (viewModel.groupedNotifications[groupKey] ?? []).last?.id {
                                Divider()
                                    .padding(.leading, 80)
                            }
                        }
                    } header: {
                        GroupHeaderView(title: groupKey)
                    }
                }
            }
            .padding(.bottom, 100) // Extra padding for tab bar
        }
    }
    
    private func sortGroupKeys(_ lhs: String, _ rhs: String) -> Bool {
        // Sort groups: Today, Yesterday, then by date
        if lhs == "Today" && rhs != "Today" { return true }
        if rhs == "Today" && lhs != "Today" { return false }
        if lhs == "Yesterday" && rhs != "Yesterday" && rhs != "Today" { return true }
        if rhs == "Yesterday" && lhs != "Yesterday" && lhs != "Today" { return false }
        return lhs > rhs // Most recent dates first
    }
}

// MARK: - Group Header View
private struct GroupHeaderView: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.brandDarkBlue)
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
    }
}

// MARK: - Notification Row View
struct NotificationRowView: View {
    let notification: Notification
    let isSelected: Bool
    let isSelectionMode: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void
    let onAction: (NotificationAction) -> Void
    
    @State private var showingActionSheet = false
    @State private var offset: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 12) {
            // Selection indicator
            if isSelectionMode {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .brandDarkBlue : .gray)
                    .font(.title3)
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
            }
            
            // Notification icon and badge
            NotificationBadgeView(
                type: notification.type,
                priority: notification.priority,
                isRead: notification.isRead
            )
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(notification.title)
                        .font(.subheadline)
                        .fontWeight(notification.isRead ? .regular : .semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(notification.displayTime)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(notification.body)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Actions (if any)
                if !notification.actions.isEmpty && !isSelectionMode {
                    NotificationActionsView(
                        actions: notification.actions,
                        onAction: onAction
                    )
                    .padding(.top, 4)
                }
            }
            
            // Chevron or menu
            if !isSelectionMode {
                Button {
                    showingActionSheet = true
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }
        }
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(notification.isRead ? Color.clear : Color.blue.opacity(0.05))
                .animation(.easeInOut(duration: 0.3), value: notification.isRead)
        )
        .offset(x: offset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if !isSelectionMode {
                        offset = value.translation.x
                    }
                }
                .onEnded { value in
                    if !isSelectionMode {
                        if abs(offset) > 100 {
                            // Perform swipe action
                            if offset > 0 {
                                // Swipe right - mark as read
                                onAction(.view)
                            } else {
                                // Swipe left - archive
                                onAction(.archive)
                            }
                        }
                        
                        withAnimation(.spring()) {
                            offset = 0
                        }
                    }
                }
        )
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture {
            onLongPress()
        }
        .contextMenu {
            NotificationContextMenu(notification: notification, onAction: onAction)
        }
        .actionSheet(isPresented: $showingActionSheet) {
            NotificationActionSheet(notification: notification, onAction: onAction)
        }
    }
}

// MARK: - Notification Actions View
private struct NotificationActionsView: View {
    let actions: [NotificationAction]
    let onAction: (NotificationAction) -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(actions.prefix(3)) { action in
                Button {
                    onAction(action)
                } label: {
                    Text(action.title)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(actionColor(for: action.style))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(actionBackgroundColor(for: action.style))
                        )
                }
            }
            
            Spacer()
        }
    }
    
    private func actionColor(for style: ActionStyle) -> Color {
        switch style {
        case .primary: return .white
        case .destructive: return .white
        case .default: return .brandDarkBlue
        case .cancel: return .gray
        }
    }
    
    private func actionBackgroundColor(for style: ActionStyle) -> Color {
        switch style {
        case .primary: return .brandDarkBlue
        case .destructive: return .red
        case .default: return .brandDarkBlue.opacity(0.1)
        case .cancel: return .gray.opacity(0.1)
        }
    }
}

// MARK: - Notification Context Menu
private struct NotificationContextMenu: View {
    let notification: Notification
    let onAction: (NotificationAction) -> Void
    
    var body: some View {
        Group {
            if !notification.isRead {
                Button {
                    onAction(.view)
                } label: {
                    Label("Mark as Read", systemImage: "envelope.open")
                }
            }
            
            Button {
                onAction(.archive)
            } label: {
                Label("Archive", systemImage: "archivebox")
            }
            
            if notification.type.allowsActions {
                Button {
                    onAction(.share)
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            }
            
            Divider()
            
            Button(role: .destructive) {
                onAction(.delete)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Notification Action Sheet
private struct NotificationActionSheet: ActionSheet {
    let notification: Notification
    let onAction: (NotificationAction) -> Void
    
    init(notification: Notification, onAction: @escaping (NotificationAction) -> Void) {
        self.notification = notification
        self.onAction = onAction
        
        var buttons: [ActionSheet.Button] = []
        
        // Add action buttons
        for action in notification.actions {
            let button: ActionSheet.Button
            
            switch action.style {
            case .destructive:
                button = .destructive(Text(action.title)) {
                    onAction(action)
                }
            default:
                button = .default(Text(action.title)) {
                    onAction(action)
                }
            }
            
            buttons.append(button)
        }
        
        // Add default actions
        if !notification.isRead {
            buttons.append(.default(Text("Mark as Read")) {
                onAction(.view)
            })
        }
        
        buttons.append(.default(Text("Archive")) {
            onAction(.archive)
        })
        
        buttons.append(.destructive(Text("Delete")) {
            onAction(.delete)
        })
        
        buttons.append(.cancel())
        
        super.init(
            title: Text(notification.title),
            message: Text(notification.body),
            buttons: buttons
        )
    }
}

// MARK: - Preview
struct NotificationListView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationListView(
            viewModel: NotificationCenterViewModel(),
            actionViewModel: NotificationActionViewModel()
        )
    }
}