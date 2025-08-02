import SwiftUI

/// Example integration of notification types with menus and action sheets
struct NotificationIntegrationExample: View {
    @StateObject private var notificationViewModel = NotificationSettingsViewModel()
    @State private var showingActionSheet = false
    @State private var selectedNotification: NotificationItem?
    @State private var showingCreateSheet = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.mainAppGradient.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Example Menu Integration
                    menuExampleSection
                    
                    // Example Action Sheet Integration
                    actionSheetExampleSection
                    
                    // Example Context Menu Integration
                    contextMenuExampleSection
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Integration Examples")
            .sheet(isPresented: $showingCreateSheet) {
                createNotificationSheet
            }
            .actionSheet(isPresented: $showingActionSheet) {
                notificationActionSheet
            }
        }
    }
    
    // MARK: - Menu Example Section
    private var menuExampleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Menu Integration Example")
                .font(.headline)
                .foregroundColor(Color.brandDarkBlue)
            
            Menu("Notification Actions") {
                // Primary actions menu section
                Section("Primary Actions") {
                    ForEach(NotificationAction.primaryActions, id: \.self) { action in
                        Button(action: {
                            handleNotificationAction(action)
                        }) {
                            Label(action.displayName, systemImage: action.systemIcon)
                        }
                    }
                }
                
                // Secondary actions menu section
                Section("Secondary Actions") {
                    ForEach(NotificationAction.secondaryActions, id: \.self) { action in
                        Button(action: {
                            handleNotificationAction(action)
                        }) {
                            Label(action.displayName, systemImage: action.systemIcon)
                        }
                    }
                }
                
                // Destructive actions menu section
                Section {
                    ForEach(NotificationAction.destructiveActions, id: \.self) { action in
                        Button(role: action.isDestructive ? .destructive : nil, action: {
                            handleNotificationAction(action)
                        }) {
                            Label(action.displayName, systemImage: action.systemIcon)
                        }
                    }
                }
            }
            .buttonStyle(PrimaryActionButtonStyle())
            
            Text("This demonstrates how NotificationAction enum integrates with SwiftUI Menus, providing organized action groups with proper icons and destructive styling.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(.white.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Action Sheet Example Section
    private var actionSheetExampleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Action Sheet Integration Example")
                .font(.headline)
                .foregroundColor(Color.brandDarkBlue)
            
            Button("Show Notification Action Sheet") {
                // Create a sample notification for the action sheet
                selectedNotification = NotificationItem(
                    type: .sifReceived,
                    title: "Sample Notification",
                    message: "This is a sample notification for action sheet demo"
                )
                showingActionSheet = true
            }
            .buttonStyle(PrimaryActionButtonStyle())
            
            Text("This shows how NotificationAction enum works with action sheets, automatically handling destructive actions and providing appropriate icons.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(.white.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Context Menu Example Section
    private var contextMenuExampleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Context Menu Integration Example")
                .font(.headline)
                .foregroundColor(Color.brandDarkBlue)
            
            VStack(spacing: 8) {
                ForEach(NotificationType.allCases.prefix(3), id: \.self) { type in
                    HStack {
                        Image(systemName: type.systemIcon)
                            .foregroundColor(type.defaultPriority.color)
                        
                        VStack(alignment: .leading) {
                            Text(type.displayName)
                                .font(.body.weight(.medium))
                            Text("Long press for context menu")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(.white.opacity(0.7))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .contextMenu {
                        // Context menu using notification actions
                        ForEach(NotificationAction.allActions.prefix(5), id: \.self) { action in
                            Button(action: {
                                handleNotificationAction(action, for: type)
                            }) {
                                Label(action.displayName, systemImage: action.systemIcon)
                            }
                        }
                    }
                }
            }
            
            Text("Long press on any notification type above to see the context menu with NotificationAction integration.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(.white.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Create Notification Sheet
    private var createNotificationSheet: some View {
        NavigationStack {
            ZStack {
                Color.mainAppGradient.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("Create Custom Notification")
                        .font(.headline)
                        .foregroundColor(Color.brandDarkBlue)
                    
                    VStack(spacing: 16) {
                        ForEach(NotificationType.allCases, id: \.self) { type in
                            Button(action: {
                                createSampleNotification(type: type)
                                showingCreateSheet = false
                            }) {
                                HStack {
                                    Image(systemName: type.systemIcon)
                                        .frame(width: 30)
                                    
                                    VStack(alignment: .leading) {
                                        Text(type.displayName)
                                            .font(.body.weight(.medium))
                                        Text("Priority: \(type.defaultPriority.displayName)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Circle()
                                        .fill(type.defaultPriority.color)
                                        .frame(width: 12, height: 12)
                                }
                                .foregroundColor(Color.brandDarkBlue)
                                .padding()
                                .background(.white.opacity(0.8))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Create Notification")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        showingCreateSheet = false
                    }
                }
            }
        }
    }
    
    // MARK: - Action Sheet
    private var notificationActionSheet: ActionSheet {
        guard let notification = selectedNotification else {
            return ActionSheet(title: Text("No notification selected"))
        }
        
        var buttons: [ActionSheet.Button] = []
        
        // Add primary actions
        for action in NotificationAction.primaryActions {
            buttons.append(.default(Text(action.displayName)) {
                handleNotificationAction(action, notification: notification)
            })
        }
        
        // Add secondary actions
        for action in NotificationAction.secondaryActions {
            buttons.append(.default(Text(action.displayName)) {
                handleNotificationAction(action, notification: notification)
            })
        }
        
        // Add destructive actions
        for action in NotificationAction.destructiveActions {
            if action.isDestructive {
                buttons.append(.destructive(Text(action.displayName)) {
                    handleNotificationAction(action, notification: notification)
                })
            } else {
                buttons.append(.default(Text(action.displayName)) {
                    handleNotificationAction(action, notification: notification)
                })
            }
        }
        
        // Add cancel button
        buttons.append(.cancel())
        
        return ActionSheet(
            title: Text(notification.title),
            message: Text("Choose an action for this notification"),
            buttons: buttons
        )
    }
    
    // MARK: - Helper Methods
    private func handleNotificationAction(_ action: NotificationAction, for type: NotificationType? = nil, notification: NotificationItem? = nil) {
        print("Handled action: \(action.displayName)")
        if let type = type {
            print("For notification type: \(type.displayName)")
        }
        if let notification = notification {
            print("For notification: \(notification.title)")
            notificationViewModel.performAction(action, on: notification)
        }
    }
    
    private func createSampleNotification(type: NotificationType) {
        let sampleMessages: [NotificationType: (title: String, message: String)] = [
            .sifReceived: ("New SIF from Alex", "Thanks for being such a great friend!"),
            .sifScheduled: ("SIF Scheduled", "Your anniversary message is scheduled for next week."),
            .sifDelivered: ("SIF Delivered", "Your thank you note to your teacher was delivered."),
            .reminder: ("Reminder", "Don't forget your dentist appointment tomorrow."),
            .systemUpdate: ("App Update", "New emoji reactions are now available!"),
            .welcome: ("Welcome Back!", "We're glad to see you again. What would you like to create today?")
        ]
        
        if let content = sampleMessages[type] {
            notificationViewModel.createNotification(
                type: type,
                title: content.title,
                message: content.message,
                priority: type.defaultPriority
            )
        }
    }
}

struct NotificationIntegrationExample_Previews: PreviewProvider {
    static var previews: some View {
        NotificationIntegrationExample()
    }
}