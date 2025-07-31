import SwiftUI

// MARK: - Notification Center View
struct NotificationCenterView: View {
    @StateObject private var viewModel = NotificationCenterViewModel()
    @State private var showingFilterSheet = false
    @State private var showingSearchSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.mainAppGradient.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if viewModel.isLoading && viewModel.notifications.isEmpty {
                        loadingView
                    } else if viewModel.filteredNotifications.isEmpty {
                        emptyStateView
                    } else {
                        notificationContent
                    }
                }
            }
            .navigationTitle("Notification Center")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $viewModel.searchText, prompt: "Search notifications...")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    notificationToolbar
                }
            }
            .sheet(isPresented: $showingFilterSheet) {
                FilterSheet(viewModel: viewModel)
            }
            .alert("Clear All Notifications", isPresented: $viewModel.showingClearAllAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear All", role: .destructive) {
                    viewModel.confirmClearAll()
                }
            } message: {
                Text("This will permanently delete all notifications. This action cannot be undone.")
            }
            .onAppear {
                viewModel.loadNotifications()
            }
            .refreshable {
                viewModel.refresh()
            }
        }
    }
    
    // MARK: - Content Views
    private var notificationContent: some View {
        VStack(spacing: 0) {
            // Summary header
            if viewModel.totalNotifications > 0 {
                summaryHeader
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
            
            // Filter pills
            if viewModel.selectedFilter != .all || !viewModel.searchText.isEmpty {
                activeFiltersView
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
            
            // Grouped notifications
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.groupedNotifications) { group in
                        NotificationGroupView(
                            group: group,
                            onNotificationTap: { notification in
                                handleNotificationTap(notification)
                            },
                            onMarkAsRead: { notification in
                                viewModel.markAsRead(notification)
                            },
                            onDelete: { notification in
                                viewModel.deleteNotification(notification)
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var summaryHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(NotificationFormatter.formatNotificationSummary(for: viewModel.notifications))
                    .font(.headline)
                    .fontWeight(.semibold)
                
                if viewModel.unreadCount > 0 {
                    Text("\(viewModel.unreadCount) unread")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
            
            if viewModel.unreadCount > 0 {
                Button("Mark All Read") {
                    viewModel.markAllAsRead()
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
    
    private var activeFiltersView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if viewModel.selectedFilter != .all {
                    FilterPillView(
                        title: viewModel.selectedFilter.displayName,
                        icon: viewModel.selectedFilter.iconName,
                        isActive: true,
                        onTap: {
                            viewModel.clearFilter()
                        }
                    )
                }
                
                if !viewModel.searchText.isEmpty {
                    FilterPillView(
                        title: "Search: \(viewModel.searchText)",
                        icon: "magnifyingglass",
                        isActive: true,
                        onTap: {
                            viewModel.clearSearch()
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: getEmptyStateIcon())
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text(getEmptyStateTitle())
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(getEmptyStateMessage())
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            if viewModel.selectedFilter != .all || !viewModel.searchText.isEmpty {
                Button("Clear Filters") {
                    viewModel.clearFilter()
                }
                .buttonStyle(SecondaryActionButtonStyle())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading notifications...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Toolbar
    private var notificationToolbar: some View {
        HStack(spacing: 16) {
            Button(action: {
                showingFilterSheet = true
            }) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .foregroundColor(viewModel.selectedFilter != .all ? .blue : .primary)
            }
            
            Menu {
                if viewModel.totalNotifications > 0 {
                    Button("Mark All as Read") {
                        viewModel.markAllAsRead()
                    }
                    
                    Button("Clear All", role: .destructive) {
                        viewModel.clearAllNotifications()
                    }
                    
                    Divider()
                }
                
                Button("Refresh") {
                    viewModel.refresh()
                }
                
                Button("Notification Settings") {
                    // Navigate to settings
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }
    
    // MARK: - Helper Methods
    private func handleNotificationTap(_ notification: Notification) {
        // Mark as read if not already read
        if !notification.isRead {
            viewModel.markAsRead(notification)
        }
        
        // Navigate to detail view or handle action
        // This would be implemented based on your navigation pattern
    }
    
    private func getEmptyStateIcon() -> String {
        if viewModel.selectedFilter != .all {
            return "line.3.horizontal.decrease.circle"
        } else if !viewModel.searchText.isEmpty {
            return "magnifyingglass"
        } else {
            return "bell.slash"
        }
    }
    
    private func getEmptyStateTitle() -> String {
        if viewModel.selectedFilter != .all {
            return "No \(viewModel.selectedFilter.displayName) Notifications"
        } else if !viewModel.searchText.isEmpty {
            return "No Search Results"
        } else {
            return "No Notifications"
        }
    }
    
    private func getEmptyStateMessage() -> String {
        if viewModel.selectedFilter != .all {
            return "You don't have any \(viewModel.selectedFilter.displayName.lowercased()) notifications at the moment."
        } else if !viewModel.searchText.isEmpty {
            return "Try adjusting your search terms or clearing the search to see all notifications."
        } else {
            return "You're all caught up! New notifications will appear here when they arrive."
        }
    }
}

// MARK: - Notification Group View
struct NotificationGroupView: View {
    let group: NotificationGroup
    let onNotificationTap: (Notification) -> Void
    let onMarkAsRead: (Notification) -> Void
    let onDelete: (Notification) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(group.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if group.hasUnread {
                    Text("\(group.unreadCount) new")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                }
            }
            
            VStack(spacing: 8) {
                ForEach(group.notifications) { notification in
                    NotificationRowView(
                        notification: notification,
                        displayMode: .expanded,
                        isSelected: false,
                        isSelectionMode: false,
                        onTap: {
                            onNotificationTap(notification)
                        },
                        onSelectionToggle: { }
                    )
                    .swipeActions(edge: .leading) {
                        if !notification.isRead {
                            Button("Mark as Read") {
                                onMarkAsRead(notification)
                            }
                            .tint(.blue)
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        Button("Delete") {
                            onDelete(notification)
                        }
                        .tint(.red)
                    }
                    
                    if notification.id != group.notifications.last?.id {
                        Divider()
                            .padding(.leading, 44)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

// MARK: - Filter Pill View
struct FilterPillView: View {
    let title: String
    let icon: String
    let isActive: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                
                if isActive {
                    Image(systemName: "xmark")
                        .font(.caption2)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isActive ? Color.blue : Color.secondary.opacity(0.2))
            )
            .foregroundColor(isActive ? .white : .primary)
        }
    }
}

// MARK: - Filter Sheet
struct FilterSheet: View {
    @ObservedObject var viewModel: NotificationCenterViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Filter by Category") {
                    ForEach(NotificationCategory.allCases, id: \.self) { category in
                        FilterOptionRow(
                            title: category.displayName,
                            icon: category.iconName,
                            count: viewModel.notificationsByCategory[category] ?? 0,
                            isSelected: viewModel.selectedFilter == .category(category),
                            onTap: {
                                viewModel.setFilter(.category(category))
                                dismiss()
                            }
                        )
                    }
                }
                
                Section("Filter by Priority") {
                    ForEach(NotificationPriority.allCases, id: \.self) { priority in
                        FilterOptionRow(
                            title: priority.displayName,
                            icon: priorityIcon(priority),
                            count: 0, // You'd calculate this
                            isSelected: viewModel.selectedFilter == .priority(priority),
                            onTap: {
                                viewModel.setFilter(.priority(priority))
                                dismiss()
                            }
                        )
                    }
                }
                
                Section {
                    FilterOptionRow(
                        title: "All Notifications",
                        icon: "tray.fill",
                        count: viewModel.totalNotifications,
                        isSelected: viewModel.selectedFilter == .all,
                        onTap: {
                            viewModel.setFilter(.all)
                            dismiss()
                        }
                    )
                    
                    FilterOptionRow(
                        title: "Unread Only",
                        icon: "envelope.badge",
                        count: viewModel.unreadNotifications,
                        isSelected: viewModel.selectedFilter == .unread,
                        onTap: {
                            viewModel.setFilter(.unread)
                            dismiss()
                        }
                    )
                }
            }
            .navigationTitle("Filter Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func priorityIcon(_ priority: NotificationPriority) -> String {
        switch priority {
        case .low: return "arrow.down.circle"
        case .normal: return "circle"
        case .high: return "arrow.up.circle"
        case .urgent: return "exclamationmark.circle"
        }
    }
}

// MARK: - Filter Option Row
struct FilterOptionRow: View {
    let title: String
    let icon: String
    let count: Int
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                Text(title)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if count > 0 {
                    Text("\(count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
#Preview {
    NotificationCenterView()
}