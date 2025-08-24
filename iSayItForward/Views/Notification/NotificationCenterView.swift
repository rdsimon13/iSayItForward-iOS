import SwiftUI

// MARK: - Notification Center View
struct NotificationCenterView: View {
    @StateObject private var viewModel = NotificationCenterViewModel()
    @StateObject private var actionViewModel = NotificationActionViewModel()
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.mainAppGradient.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Filter Bar
                    if viewModel.activeFilterCount > 0 {
                        FilterStatusBar(viewModel: viewModel)
                    }
                    
                    // Content
                    if viewModel.hasNotifications {
                        NotificationListView(
                            viewModel: viewModel,
                            actionViewModel: actionViewModel
                        )
                    } else {
                        EmptyNotificationsView(
                            filter: viewModel.selectedFilter,
                            onRefresh: {
                                Task {
                                    await viewModel.refreshNotifications()
                                }
                            }
                        )
                    }
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if viewModel.isSelectionMode {
                        Button("Cancel") {
                            viewModel.exitSelectionMode()
                        }
                    } else {
                        Button {
                            viewModel.showingFilterSheet = true
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .foregroundColor(.brandDarkBlue)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.isSelectionMode {
                        Menu {
                            BatchActionsMenu(viewModel: viewModel)
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    } else {
                        HStack {
                            Button {
                                showingSettings = true
                            } label: {
                                Image(systemName: "gear")
                                    .foregroundColor(.brandDarkBlue)
                            }
                            
                            if viewModel.hasNotifications {
                                Button {
                                    viewModel.enterSelectionMode()
                                } label: {
                                    Image(systemName: "checkmark.circle")
                                        .foregroundColor(.brandDarkBlue)
                                }
                            }
                        }
                    }
                }
            }
            .refreshable {
                await viewModel.refreshNotifications()
            }
            .sheet(isPresented: $viewModel.showingFilterSheet) {
                NotificationFilterSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $showingSettings) {
                NotificationSettingsView()
            }
            .alert("Batch Action", isPresented: $viewModel.showingBatchActionSheet) {
                BatchActionAlert(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Filter Status Bar
private struct FilterStatusBar: View {
    @ObservedObject var viewModel: NotificationCenterViewModel
    
    var body: some View {
        HStack {
            Text(viewModel.filterDescription)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button("Clear") {
                viewModel.clearFilters()
            }
            .font(.caption)
            .foregroundColor(.brandDarkBlue)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
}

// MARK: - Empty Notifications View
private struct EmptyNotificationsView: View {
    let filter: NotificationFilter
    let onRefresh: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: emptyStateIcon)
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text(emptyStateTitle)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(emptyStateMessage)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button("Refresh") {
                onRefresh()
            }
            .buttonStyle(SecondaryActionButtonStyle())
        }
        .padding()
    }
    
    private var emptyStateIcon: String {
        switch filter {
        case .all: return "bell.slash"
        case .unread: return "envelope.open"
        case .read: return "checkmark.circle"
        case .archived: return "archivebox"
        case .failed: return "exclamationmark.triangle"
        case .scheduled: return "calendar.badge.clock"
        }
    }
    
    private var emptyStateTitle: String {
        switch filter {
        case .all: return "No Notifications"
        case .unread: return "No Unread Notifications"
        case .read: return "No Read Notifications"
        case .archived: return "No Archived Notifications"
        case .failed: return "No Failed Notifications"
        case .scheduled: return "No Scheduled Notifications"
        }
    }
    
    private var emptyStateMessage: String {
        switch filter {
        case .all: return "You're all caught up! New notifications will appear here."
        case .unread: return "All your notifications have been read."
        case .read: return "No read notifications to show."
        case .archived: return "No archived notifications to show."
        case .failed: return "No failed notifications to show."
        case .scheduled: return "No scheduled notifications to show."
        }
    }
}

// MARK: - Batch Actions Menu
private struct BatchActionsMenu: View {
    @ObservedObject var viewModel: NotificationCenterViewModel
    
    var body: some View {
        Group {
            if viewModel.hasSelectedNotifications {
                Button {
                    viewModel.markSelectedAsRead()
                } label: {
                    Label("Mark as Read", systemImage: "envelope.open")
                }
                
                Button {
                    viewModel.archiveSelectedNotifications()
                } label: {
                    Label("Archive", systemImage: "archivebox")
                }
                
                Button(role: .destructive) {
                    viewModel.deleteSelectedNotifications()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            
            Divider()
            
            if viewModel.allVisibleSelected {
                Button {
                    viewModel.deselectAllNotifications()
                } label: {
                    Label("Deselect All", systemImage: "checkmark.circle.fill")
                }
            } else {
                Button {
                    viewModel.selectAllVisibleNotifications()
                } label: {
                    Label("Select All", systemImage: "checkmark.circle")
                }
            }
        }
    }
}

// MARK: - Batch Action Alert
private struct BatchActionAlert: View {
    @ObservedObject var viewModel: NotificationCenterViewModel
    
    var body: some View {
        Group {
            Button("Cancel", role: .cancel) {
                viewModel.showingBatchActionSheet = false
            }
            
            Button("Mark as Read") {
                viewModel.markSelectedAsRead()
                viewModel.showingBatchActionSheet = false
            }
            
            Button("Archive") {
                viewModel.archiveSelectedNotifications()
                viewModel.showingBatchActionSheet = false
            }
            
            Button("Delete", role: .destructive) {
                viewModel.deleteSelectedNotifications()
                viewModel.showingBatchActionSheet = false
            }
        }
    }
}

// MARK: - Preview
struct NotificationCenterView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationCenterView()
    }
}