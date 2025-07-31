import SwiftUI

// MARK: - Notification Demo View
struct NotificationDemoView: View {
    @StateObject private var notificationService = NotificationService.shared
    @StateObject private var authService = AuthenticationService.shared
    @State private var showingDemo = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "bell.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.brandDarkBlue)
                        
                        Text("Notification System Demo")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.brandDarkBlue)
                        
                        Text("Test the comprehensive notification features")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Status Card
                    NotificationStatusCard()
                    
                    // Demo Actions
                    VStack(spacing: 12) {
                        Text("Demo Actions")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.brandDarkBlue)
                        
                        DemoActionButton(
                            title: "Generate Sample Notifications",
                            icon: "plus.circle.fill",
                            action: generateSampleNotifications
                        )
                        
                        DemoActionButton(
                            title: "Test Push Notification",
                            icon: "bell.badge.fill",
                            action: testPushNotification
                        )
                        
                        DemoActionButton(
                            title: "Request Permissions",
                            icon: "gear.circle.fill",
                            action: requestPermissions
                        )
                        
                        DemoActionButton(
                            title: "Open Notification Center",
                            icon: "list.bullet.circle.fill",
                            action: { showingDemo = true }
                        )
                        
                        DemoActionButton(
                            title: "Clear All Notifications",
                            icon: "trash.circle.fill",
                            color: .red,
                            action: clearAllNotifications
                        )
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.white.opacity(0.9))
                            .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
                    )
                }
                .padding()
            }
            .background(Color.mainAppGradient.ignoresSafeArea())
            .navigationTitle("Notification Demo")
            .sheet(isPresented: $showingDemo) {
                NotificationCenterView()
            }
        }
    }
    
    // MARK: - Demo Actions
    private func generateSampleNotifications() {
        guard let currentUser = authService.currentAppUser else {
            // Sign in demo user first
            authService.signInDemo(email: "demo@example.com", name: "Demo User")
            
            // Wait a moment then generate notifications
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                generateSampleNotifications()
            }
            return
        }
        
        let sampleNotifications = [
            Notification(
                title: "New SIF Received! 🎉",
                body: "Sarah sent you a birthday SIF with a special video message!",
                type: .sifReceived,
                payload: NotificationPayload.sifPayload(sifId: "sif_birthday_123", senderId: "user_sarah"),
                recipientUID: currentUser.uid,
                priority: .high,
                actions: NotificationActionFactory.actionsFor(notificationType: .sifReceived)
            ),
            Notification(
                title: "Friend Request ✋",
                body: "John wants to connect with you on iSayItForward",
                type: .friendRequest,
                payload: NotificationPayload.friendRequestPayload(senderId: "user_john"),
                recipientUID: currentUser.uid,
                priority: .normal,
                actions: NotificationActionFactory.actionsFor(notificationType: .friendRequest)
            ),
            Notification(
                title: "SIF Delivered Successfully ✅",
                body: "Your anniversary SIF was delivered to Mom. She loved it!",
                type: .sifDelivered,
                recipientUID: currentUser.uid,
                priority: .normal
            ),
            Notification(
                title: "New Achievement Unlocked! 🏆",
                body: "Congratulations! You've sent 25 SIFs and earned the 'Spreader of Joy' badge!",
                type: .achievement,
                payload: NotificationPayload.achievementPayload(
                    achievementId: "spreader_of_joy",
                    metadata: ["count": "25", "type": "sifs_sent"]
                ),
                recipientUID: currentUser.uid,
                priority: .normal
            ),
            Notification(
                title: "SIF Reminder 📅",
                body: "Don't forget to send Dad a SIF for his birthday tomorrow!",
                type: .sifReminder,
                scheduledAt: Calendar.current.date(byAdding: .hour, value: 2, to: Date()),
                recipientUID: currentUser.uid,
                priority: .high
            ),
            Notification(
                title: "Message from Alex 💬",
                body: "Thanks for the SIF! It really made my day brighter. Can't wait to send one back!",
                type: .messageReceived,
                payload: NotificationPayload.messagePayload(chatId: "chat_alex_123", senderId: "user_alex"),
                recipientUID: currentUser.uid,
                priority: .normal
            )
        ]
        
        for notification in sampleNotifications {
            notificationService.addNotification(notification)
        }
        
        print("✅ Generated \(sampleNotifications.count) sample notifications")
    }
    
    private func testPushNotification() {
        guard let currentUser = authService.currentAppUser else { return }
        
        let testNotification = Notification(
            title: "Test Notification 🧪",
            body: "This is a test notification to verify your settings are working correctly.",
            type: .systemUpdate,
            recipientUID: currentUser.uid,
            priority: .normal
        )
        
        notificationService.addNotification(testNotification)
        print("✅ Test notification sent")
    }
    
    private func requestPermissions() {
        Task {
            await notificationService.requestPermissions()
            print("✅ Notification permissions requested")
        }
    }
    
    private func clearAllNotifications() {
        notificationService.clearAllNotifications()
        print("✅ All notifications cleared")
    }
}

// MARK: - Notification Status Card
private struct NotificationStatusCard: View {
    @ObservedObject private var notificationService = NotificationService.shared
    @ObservedObject private var authService = AuthenticationService.shared
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("System Status")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.brandDarkBlue)
                
                Spacer()
                
                StatusIndicator(isActive: notificationService.isPermissionGranted)
            }
            
            VStack(spacing: 8) {
                StatusRow(
                    label: "Authentication",
                    value: authService.isAuthenticated ? "✅ Signed In" : "❌ Not Signed In",
                    isGood: authService.isAuthenticated
                )
                
                StatusRow(
                    label: "Permissions",
                    value: notificationService.isPermissionGranted ? "✅ Granted" : "❌ Not Granted",
                    isGood: notificationService.isPermissionGranted
                )
                
                StatusRow(
                    label: "Notifications",
                    value: "\(notificationService.notifications.count) total",
                    isGood: true
                )
                
                StatusRow(
                    label: "Unread Count",
                    value: "\(notificationService.unreadCount)",
                    isGood: notificationService.unreadCount == 0
                )
                
                if let token = notificationService.deviceToken {
                    StatusRow(
                        label: "Device Token",
                        value: "✅ Registered",
                        isGood: true
                    )
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

// MARK: - Status Row
private struct StatusRow: View {
    let label: String
    let value: String
    let isGood: Bool
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isGood ? .green : .orange)
        }
    }
}

// MARK: - Status Indicator
private struct StatusIndicator: View {
    let isActive: Bool
    
    var body: some View {
        Circle()
            .fill(isActive ? Color.green : Color.red)
            .frame(width: 12, height: 12)
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 2)
            )
    }
}

// MARK: - Demo Action Button
private struct DemoActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    init(
        title: String,
        icon: String,
        color: Color = .brandDarkBlue,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
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
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
struct NotificationDemoView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationDemoView()
    }
}