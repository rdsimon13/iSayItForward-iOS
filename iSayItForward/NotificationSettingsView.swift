import SwiftUI

struct NotificationSettingsView: View {
    @StateObject private var userDataManager = UserDataManager()
    @State private var notificationSettings: NotificationSettings
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var hasChanges = false
    
    init(initialSettings: NotificationSettings = NotificationSettings()) {
        _notificationSettings = State(initialValue: initialSettings)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.mainAppGradient.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                            
                            Text("Notification Settings")
                                .font(.title2.weight(.bold))
                                .foregroundColor(.white)
                            
                            Text("Customize how you receive notifications")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.top)
                        
                        // Main Notifications
                        SettingsSection(title: "Main Notifications") {
                            NotificationToggle(
                                title: "Push Notifications",
                                subtitle: "Receive notifications on this device",
                                isOn: $notificationSettings.pushNotificationsEnabled,
                                onChange: markAsChanged
                            )
                            
                            NotificationToggle(
                                title: "Email Notifications", 
                                subtitle: "Receive notifications via email",
                                isOn: $notificationSettings.emailNotificationsEnabled,
                                onChange: markAsChanged
                            )
                        }
                        
                        // SIF Notifications
                        SettingsSection(title: "SIF Notifications") {
                            NotificationToggle(
                                title: "New SIF Messages",
                                subtitle: "When you receive a new SIF",
                                isOn: $notificationSettings.newSIFNotifications,
                                onChange: markAsChanged
                            )
                            
                            NotificationToggle(
                                title: "Scheduled SIF Reminders",
                                subtitle: "Reminders for your scheduled SIFs",
                                isOn: $notificationSettings.scheduledSIFReminders,
                                onChange: markAsChanged
                            )
                            
                            NotificationToggle(
                                title: "Friend Requests",
                                subtitle: "When someone sends you a friend request",
                                isOn: $notificationSettings.friendRequestNotifications,
                                onChange: markAsChanged
                            )
                        }
                        
                        // Marketing
                        SettingsSection(title: "Marketing") {
                            NotificationToggle(
                                title: "Marketing Notifications",
                                subtitle: "Updates and promotional content",
                                isOn: $notificationSettings.marketingNotifications,
                                onChange: markAsChanged
                            )
                        }
                        
                        // Sound & Vibration
                        SettingsSection(title: "Sound & Vibration") {
                            NotificationToggle(
                                title: "Sound",
                                subtitle: "Play sound for notifications",
                                isOn: $notificationSettings.soundEnabled,
                                onChange: markAsChanged
                            )
                            
                            NotificationToggle(
                                title: "Vibration",
                                subtitle: "Vibrate for notifications",
                                isOn: $notificationSettings.vibrationEnabled,
                                onChange: markAsChanged
                            )
                        }
                        
                        // Quiet Hours
                        SettingsSection(title: "Quiet Hours") {
                            NotificationToggle(
                                title: "Enable Quiet Hours",
                                subtitle: "Disable notifications during specific hours",
                                isOn: $notificationSettings.quietHoursEnabled,
                                onChange: markAsChanged
                            )
                            
                            if notificationSettings.quietHoursEnabled {
                                QuietHoursSettings(
                                    startTime: $notificationSettings.quietHoursStart,
                                    endTime: $notificationSettings.quietHoursEnd,
                                    onChange: markAsChanged
                                )
                            }
                        }
                        
                        // Save Button
                        if hasChanges {
                            Button("Save Changes") {
                                Task {
                                    await saveSettings()
                                }
                            }
                            .buttonStyle(PrimaryActionButtonStyle())
                            .disabled(userDataManager.isLoading)
                        }
                        
                        if userDataManager.isLoading {
                            ProgressView("Saving...")
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Settings", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                loadCurrentSettings()
            }
        }
    }
    
    private func markAsChanged() {
        hasChanges = true
    }
    
    private func loadCurrentSettings() {
        if let currentUser = userDataManager.currentUser {
            notificationSettings = currentUser.notificationSettings
        }
    }
    
    private func saveSettings() async {
        await userDataManager.updateNotificationSettings(notificationSettings)
        
        if let error = userDataManager.errorMessage {
            alertMessage = error
            showingAlert = true
        } else {
            alertMessage = "Notification settings saved successfully!"
            showingAlert = true
            hasChanges = false
        }
    }
}

// MARK: - Supporting Views

private struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 0) {
                content
            }
            .background(.white.opacity(0.85))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
        }
    }
}

private struct NotificationToggle: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    let onChange: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(Color.brandDarkBlue)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .tint(Color.brandDarkBlue)
                .onChange(of: isOn) { _ in
                    onChange()
                }
        }
        .padding()
        .background(Color.clear)
    }
}

private struct QuietHoursSettings: View {
    @Binding var startTime: String
    @Binding var endTime: String
    let onChange: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Start Time")
                    .font(.body)
                    .foregroundColor(Color.brandDarkBlue)
                
                Spacer()
                
                TextField("Start", text: $startTime)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 80)
                    .onChange(of: startTime) { _ in
                        onChange()
                    }
            }
            
            HStack {
                Text("End Time")
                    .font(.body)
                    .foregroundColor(Color.brandDarkBlue)
                
                Spacer()
                
                TextField("End", text: $endTime)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 80)
                    .onChange(of: endTime) { _ in
                        onChange()
                    }
            }
        }
        .padding()
    }
}

#Preview {
    NotificationSettingsView()
}