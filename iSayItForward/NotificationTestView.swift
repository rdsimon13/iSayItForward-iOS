import SwiftUI

/// A simple test view to demonstrate notification types integration
struct NotificationTestView: View {
    @StateObject private var viewModel = NotificationSettingsViewModel()
    @State private var showingNotificationList = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.mainAppGradient.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Test notification creation buttons
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Test Notification Creation")
                                .font(.headline)
                                .foregroundColor(Color.brandDarkBlue)
                            
                            ForEach(NotificationType.allCases, id: \.self) { type in
                                Button("Create \(type.displayName)") {
                                    createTestNotification(type: type)
                                }
                                .buttonStyle(PrimaryActionButtonStyle())
                            }
                        }
                        .padding()
                        .background(.white.opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                        // Notification actions demo
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Available Actions")
                                .font(.headline)
                                .foregroundColor(Color.brandDarkBlue)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
                                ForEach(NotificationAction.allCases, id: \.self) { action in
                                    VStack {
                                        Image(systemName: action.systemIcon)
                                            .font(.title2)
                                            .foregroundColor(action.isDestructive ? .red : Color.brandDarkBlue)
                                        
                                        Text(action.displayName)
                                            .font(.caption)
                                            .multilineTextAlignment(.center)
                                    }
                                    .padding(8)
                                    .background(.white.opacity(0.7))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                        .padding()
                        .background(.white.opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                        // Priority levels demo
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Priority Levels")
                                .font(.headline)
                                .foregroundColor(Color.brandDarkBlue)
                            
                            ForEach(NotificationPriority.allCases, id: \.self) { priority in
                                HStack {
                                    Circle()
                                        .fill(priority.color)
                                        .frame(width: 20, height: 20)
                                    
                                    Text(priority.displayName)
                                        .font(.body)
                                        .foregroundColor(Color.brandDarkBlue)
                                    
                                    Spacer()
                                    
                                    Text("Level \(priority.rawValue)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .padding()
                        .background(.white.opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                        // Statistics
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Notification Statistics")
                                .font(.headline)
                                .foregroundColor(Color.brandDarkBlue)
                            
                            HStack {
                                StatCard(title: "Unread", value: "\(viewModel.unreadCount)")
                                StatCard(title: "High Priority", value: "\(viewModel.highPriorityUnread.count)")
                                StatCard(title: "Recent", value: "\(viewModel.recentNotifications.count)")
                            }
                        }
                        .padding()
                        .background(.white.opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding()
                }
            }
            .navigationTitle("Notification Test")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("View All") {
                        showingNotificationList = true
                    }
                }
            }
            .sheet(isPresented: $showingNotificationList) {
                NotificationListView(viewModel: viewModel)
            }
        }
    }
    
    private func createTestNotification(type: NotificationType) {
        let messages: [NotificationType: (title: String, message: String)] = [
            .sifReceived: ("New SIF from John", "Happy Birthday! Hope you have a wonderful day."),
            .sifScheduled: ("SIF Scheduled", "Your birthday message to Sarah is scheduled for tomorrow."),
            .sifDelivered: ("SIF Delivered", "Your message to Mom has been delivered successfully."),
            .reminder: ("Reminder", "Don't forget to send a SIF to your friend today!"),
            .systemUpdate: ("System Update", "New features are now available in the app."),
            .welcome: ("Welcome!", "Thanks for joining iSayItForward. Start sending SIFs today!")
        ]
        
        if let content = messages[type] {
            viewModel.createNotification(
                type: type,
                title: content.title,
                message: content.message,
                priority: type.defaultPriority
            )
        }
    }
}

/// A small statistics card
private struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack {
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundColor(Color.brandDarkBlue)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.white.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

/// A view to display the list of notifications
private struct NotificationListView: View {
    @ObservedObject var viewModel: NotificationSettingsViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.mainAppGradient.ignoresSafeArea()
                
                if viewModel.notifications.isEmpty {
                    VStack {
                        Image(systemName: "bell.slash")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        
                        Text("No notifications")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("Create some test notifications to see them here.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List(viewModel.notifications) { notification in
                        NotificationRowView(notification: notification, viewModel: viewModel)
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                if !viewModel.notifications.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Mark All Read") {
                            viewModel.markAllAsRead()
                        }
                    }
                }
            }
        }
    }
}

/// A row view for displaying a notification
private struct NotificationRowView: View {
    let notification: NotificationItem
    @ObservedObject var viewModel: NotificationSettingsViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Type icon with priority color
            Image(systemName: notification.type.systemIcon)
                .font(.title2)
                .foregroundColor(notification.priority.color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                    .font(.headline)
                    .foregroundColor(notification.isRead ? .secondary : .primary)
                
                Text(notification.message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Text(notification.createdDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if !notification.isRead {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 4)
        .contextMenu {
            ForEach(NotificationAction.primaryActions, id: \.self) { action in
                Button(action: {
                    viewModel.performAction(action, on: notification)
                }) {
                    Label(action.displayName, systemImage: action.systemIcon)
                }
            }
            
            Divider()
            
            ForEach(NotificationAction.secondaryActions, id: \.self) { action in
                Button(action: {
                    viewModel.performAction(action, on: notification)
                }) {
                    Label(action.displayName, systemImage: action.systemIcon)
                }
            }
            
            Divider()
            
            ForEach(NotificationAction.destructiveActions, id: \.self) { action in
                Button(role: action.isDestructive ? .destructive : nil, action: {
                    viewModel.performAction(action, on: notification)
                }) {
                    Label(action.displayName, systemImage: action.systemIcon)
                }
            }
        }
    }
}

struct NotificationTestView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationTestView()
    }
}