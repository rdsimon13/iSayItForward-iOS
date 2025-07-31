import SwiftUI

// MARK: - Notification List View
struct NotificationListView: View {
    @StateObject private var viewModel = NotificationListViewModel()
    @State private var displayMode: NotificationListDisplayMode = .expanded
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.mainAppGradient.ignoresSafeArea()
                
                if viewModel.notifications.isEmpty && !viewModel.isLoading {
                    emptyStateView
                } else {
                    notificationListContent
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    toolbarMenu
                }
                
                if viewModel.isSelectionMode {
                    ToolbarItem(placement: .navigationBarLeading) {
                        selectionToolbar
                    }
                }
            }
            .refreshable {
                await refreshNotifications()
            }
            .onAppear {
                viewModel.loadNotifications()
            }
        }
    }
    
    // MARK: - List Content
    private var notificationListContent: some View {
        List {
            ForEach(Array(viewModel.notifications.enumerated()), id: \.element.id) { index, notification in
                NotificationRowView(
                    notification: notification,
                    displayMode: displayMode,
                    isSelected: viewModel.isSelected(notification.id ?? ""),
                    isSelectionMode: viewModel.isSelectionMode,
                    onTap: {
                        handleNotificationTap(notification)
                    },
                    onSelectionToggle: {
                        viewModel.toggleSelection(for: notification.id ?? "")
                    }
                )
                .swipeActions(edge: .leading) {
                    ForEach(viewModel.getLeadingSwipeActions(for: notification), id: \.title) { action in
                        Button(action.title) {
                            action.action()
                        }
                        .tint(action.backgroundColor)
                    }
                }
                .swipeActions(edge: .trailing) {
                    ForEach(viewModel.getTrailingSwipeActions(for: notification), id: \.title) { action in
                        Button(action.title) {
                            action.action()
                        }
                        .tint(action.backgroundColor)
                    }
                }
                .onAppear {
                    if viewModel.shouldShowLoadingIndicator(for: index) {
                        viewModel.loadNextPage()
                    }
                }
            }
            
            if viewModel.canLoadMore {
                loadingIndicator
            }
        }
        .listStyle(PlainListStyle())
        .background(Color.clear)
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Notifications")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("You're all caught up! New notifications will appear here.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button("Refresh") {
                viewModel.refresh()
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .padding(.top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Loading Indicator
    private var loadingIndicator: some View {
        HStack {
            Spacer()
            ProgressView()
                .scaleEffect(0.8)
            Text("Loading more...")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Toolbar
    private var toolbarMenu: some View {
        Menu {
            if !viewModel.notifications.isEmpty {
                Button(action: {
                    viewModel.enterSelectionMode()
                }) {
                    Label("Select", systemImage: "checkmark.circle")
                }
                
                Button(action: {
                    viewModel.markSelectedAsRead()
                }) {
                    Label("Mark All as Read", systemImage: "envelope.open")
                }
                
                Divider()
            }
            
            Menu("Display Mode") {
                Button(action: { displayMode = .compact }) {
                    Label("Compact", systemImage: displayMode == .compact ? "checkmark" : "")
                }
                
                Button(action: { displayMode = .expanded }) {
                    Label("Expanded", systemImage: displayMode == .expanded ? "checkmark" : "")
                }
                
                Button(action: { displayMode = .card }) {
                    Label("Card", systemImage: displayMode == .card ? "checkmark" : "")
                }
            }
            
            Button(action: {
                viewModel.refresh()
            }) {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
    
    private var selectionToolbar: some View {
        HStack(spacing: 16) {
            Button("Cancel") {
                viewModel.exitSelectionMode()
            }
            
            if viewModel.selectedCount > 0 {
                Text("\(viewModel.selectedCount) selected")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button(action: {
                    viewModel.markSelectedAsRead()
                }) {
                    Image(systemName: "envelope.open")
                }
                
                Button(action: {
                    viewModel.deleteSelected()
                }) {
                    Image(systemName: "trash")
                }
                .foregroundColor(.red)
            }
        }
    }
    
    // MARK: - Actions
    private func handleNotificationTap(_ notification: Notification) {
        if viewModel.isSelectionMode {
            viewModel.toggleSelection(for: notification.id ?? "")
        } else {
            // Navigate to notification detail
            // This would be handled by the parent navigation
        }
    }
    
    @MainActor
    private func refreshNotifications() async {
        viewModel.refresh()
        
        // Wait for refresh to complete
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
    }
}

// MARK: - Notification Row View
struct NotificationRowView: View {
    let notification: Notification
    let displayMode: NotificationListDisplayMode
    let isSelected: Bool
    let isSelectionMode: Bool
    let onTap: () -> Void
    let onSelectionToggle: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                if isSelectionMode {
                    selectionIndicator
                }
                
                notificationIcon
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(notification.title)
                            .font(.headline)
                            .fontWeight(notification.isRead ? .medium : .semibold)
                            .foregroundColor(notification.isRead ? .secondary : .primary)
                        
                        Spacer()
                        
                        timeLabel
                    }
                    
                    if displayMode.showsFullMessage {
                        Text(NotificationFormatter.formatMessage(for: notification))
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineLimit(displayMode == .card ? 3 : 2)
                    } else {
                        Text(NotificationFormatter.formatPreviewText(for: notification))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    if displayMode.showsActions && !isSelectionMode {
                        quickActionButtons
                    }
                }
                
                Spacer()
                
                if !notification.isRead {
                    unreadIndicator
                }
            }
            .padding(.vertical, displayMode == .compact ? 8 : 12)
            .frame(minHeight: displayMode.cellHeight)
            .background(
                RoundedRectangle(cornerRadius: displayMode == .card ? 12 : 0)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var selectionIndicator: some View {
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
            .foregroundColor(isSelected ? .blue : .gray)
            .font(.title3)
            .onTapGesture {
                onSelectionToggle()
            }
    }
    
    private var notificationIcon: some View {
        Image(systemName: notification.type.iconName)
            .font(.title2)
            .foregroundColor(Color(notification.type.color))
            .frame(width: 32, height: 32)
            .background(
                Circle()
                    .fill(Color(notification.type.color).opacity(0.1))
            )
    }
    
    private var timeLabel: some View {
        Text(NotificationFormatter.formatTime(from: notification.createdDate))
            .font(.caption)
            .foregroundColor(.secondary)
    }
    
    private var unreadIndicator: some View {
        Circle()
            .fill(.blue)
            .frame(width: 8, height: 8)
    }
    
    private var quickActionButtons: some View {
        HStack(spacing: 12) {
            if !notification.isRead {
                Button("Mark as Read") {
                    // Handle mark as read
                }
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(8)
            }
            
            if notification.type == .messageResponse || notification.type == .mention {
                Button("Reply") {
                    // Handle reply
                }
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.1))
                .foregroundColor(.green)
                .cornerRadius(8)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    NotificationListView()
}