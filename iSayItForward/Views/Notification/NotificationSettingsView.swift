import SwiftUI

// MARK: - Notification Settings View
struct NotificationSettingsView: View {
    @StateObject private var viewModel = NotificationSettingsViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Status Section
                    NotificationStatusSection(viewModel: viewModel)
                    
                    // Main Settings
                    NotificationMainSettingsSection(viewModel: viewModel)
                    
                    // Category Settings
                    NotificationCategorySettingsSection(viewModel: viewModel)
                    
                    // Quiet Hours
                    NotificationQuietHoursSection(viewModel: viewModel)
                    
                    // Advanced Settings
                    NotificationAdvancedSettingsSection(viewModel: viewModel)
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
            .background(Color.mainAppGradient.ignoresSafeArea())
            .navigationTitle("Notification Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.brandDarkBlue)
                }
            }
            .alert("Notification Permission Required", isPresented: $viewModel.showingPermissionAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Open Settings") {
                    viewModel.openSystemSettings()
                }
            } message: {
                Text("To receive notifications, please enable them in Settings.")
            }
            .sheet(isPresented: $viewModel.showingQuietHoursSheet) {
                QuietHoursSettingsSheet(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Status Section
private struct NotificationStatusSection: View {
    @ObservedObject var viewModel: NotificationSettingsViewModel
    
    var body: some View {
        SettingsCard {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "bell.circle.fill")
                        .font(.title)
                        .foregroundColor(statusColor)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notification Status")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.brandDarkBlue)
                        
                        Text(viewModel.notificationStatusText)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    StatusIndicator(isActive: viewModel.hasValidSettings)
                }
                
                if !viewModel.isPermissionGranted {
                    Button("Request Permission") {
                        Task {
                            await viewModel.requestPermission()
                        }
                    }
                    .buttonStyle(PrimaryActionButtonStyle())
                }
                
                if let deviceToken = viewModel.deviceTokenShort {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Device Token")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Text(deviceToken)
                            .font(.caption)
                            .fontFamily(.monospaced)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }
    
    private var statusColor: Color {
        if !viewModel.isPermissionGranted {
            return .red
        } else if !viewModel.settings.isEnabled {
            return .orange
        } else if viewModel.isCurrentlyInQuietHours {
            return .yellow
        } else {
            return .green
        }
    }
}

// MARK: - Main Settings Section
private struct NotificationMainSettingsSection: View {
    @ObservedObject var viewModel: NotificationSettingsViewModel
    
    var body: some View {
        SettingsCard {
            VStack(spacing: 0) {
                SettingsToggleRow(
                    title: "Enable Notifications",
                    subtitle: "Receive push notifications",
                    icon: "bell.fill",
                    isOn: $viewModel.settings.isEnabled,
                    action: {
                        Task {
                            await viewModel.toggleNotifications()
                        }
                    }
                )
                
                if viewModel.settings.isEnabled {
                    Divider()
                        .padding(.leading, 50)
                    
                    SettingsToggleRow(
                        title: "Sound",
                        subtitle: "Play notification sounds",
                        icon: "speaker.wave.2.fill",
                        isOn: $viewModel.settings.soundEnabled,
                        action: viewModel.toggleSound
                    )
                    
                    Divider()
                        .padding(.leading, 50)
                    
                    SettingsToggleRow(
                        title: "Badge",
                        subtitle: "Show unread count on app icon",
                        icon: "app.badge.fill",
                        isOn: $viewModel.settings.badgeEnabled,
                        action: viewModel.toggleBadge
                    )
                }
            }
        }
    }
}

// MARK: - Category Settings Section
private struct NotificationCategorySettingsSection: View {
    @ObservedObject var viewModel: NotificationSettingsViewModel
    
    var body: some View {
        SettingsCard {
            VStack(spacing: 0) {
                HStack {
                    Text("Notification Types")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.brandDarkBlue)
                    
                    Spacer()
                    
                    Text("\(viewModel.enabledNotificationTypesCount) enabled")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 16)
                
                SettingsToggleRow(
                    title: "SIF Notifications",
                    subtitle: "SIF delivery, reminders, and updates",
                    icon: "envelope.fill",
                    iconColor: .brandDarkBlue,
                    isOn: $viewModel.settings.sifNotificationsEnabled,
                    action: viewModel.toggleSIFNotifications
                )
                
                Divider()
                    .padding(.leading, 50)
                
                SettingsToggleRow(
                    title: "Social Notifications",
                    subtitle: "Friend requests, messages, and activity",
                    icon: "person.2.fill",
                    iconColor: .green,
                    isOn: $viewModel.settings.socialNotificationsEnabled,
                    action: viewModel.toggleSocialNotifications
                )
                
                Divider()
                    .padding(.leading, 50)
                
                SettingsToggleRow(
                    title: "System Notifications",
                    subtitle: "Updates, security alerts, and achievements",
                    icon: "gear.circle.fill",
                    iconColor: .orange,
                    isOn: $viewModel.settings.systemNotificationsEnabled,
                    action: viewModel.toggleSystemNotifications
                )
            }
        }
    }
}

// MARK: - Quiet Hours Section
private struct NotificationQuietHoursSection: View {
    @ObservedObject var viewModel: NotificationSettingsViewModel
    
    var body: some View {
        SettingsCard {
            VStack(spacing: 0) {
                SettingsToggleRow(
                    title: "Quiet Hours",
                    subtitle: viewModel.settings.quietHoursEnabled ? viewModel.quietHoursDescription : "Mute notifications during specified hours",
                    icon: "moon.fill",
                    iconColor: .purple,
                    isOn: $viewModel.settings.quietHoursEnabled,
                    action: viewModel.toggleQuietHours
                )
                
                if viewModel.settings.quietHoursEnabled {
                    Divider()
                        .padding(.leading, 50)
                    
                    Button {
                        viewModel.showingQuietHoursSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.purple)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Configure Hours")
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                
                                Text(viewModel.quietHoursDescription)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

// MARK: - Advanced Settings Section
private struct NotificationAdvancedSettingsSection: View {
    @ObservedObject var viewModel: NotificationSettingsViewModel
    
    var body: some View {
        SettingsCard {
            VStack(spacing: 0) {
                HStack {
                    Text("Advanced")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.brandDarkBlue)
                    
                    Spacer()
                }
                .padding(.bottom, 16)
                
                SettingsActionRow(
                    title: "Send Test Notification",
                    subtitle: "Test your notification settings",
                    icon: "bell.badge",
                    iconColor: .blue,
                    action: {
                        Task {
                            await viewModel.sendTestNotification()
                        }
                    }
                )
                
                Divider()
                    .padding(.leading, 50)
                
                SettingsActionRow(
                    title: "Reset to Defaults",
                    subtitle: "Restore default notification settings",
                    icon: "arrow.clockwise",
                    iconColor: .gray,
                    action: viewModel.resetToDefaults
                )
            }
        }
    }
}

// MARK: - Settings Card
private struct SettingsCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack {
            content
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.9))
                .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
        )
    }
}

// MARK: - Settings Toggle Row
private struct SettingsToggleRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    @Binding var isOn: Bool
    let action: () -> Void
    
    init(
        title: String,
        subtitle: String,
        icon: String,
        iconColor: Color = .brandDarkBlue,
        isOn: Binding<Bool>,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.iconColor = iconColor
        self._isOn = isOn
        self.action = action
    }
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(iconColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .onChange(of: isOn) { _ in
                    action()
                }
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Settings Action Row
private struct SettingsActionRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
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
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
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

// MARK: - Quiet Hours Settings Sheet
private struct QuietHoursSettingsSheet: View {
    @ObservedObject var viewModel: NotificationSettingsViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Quiet Hours")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.brandDarkBlue)
                    
                    Text("During quiet hours, you'll only receive critical notifications. All other notifications will be silently delivered.")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 20) {
                    TimePickerRow(
                        title: "Start Time",
                        time: viewModel.quietHoursStartTime,
                        onChange: viewModel.updateQuietHoursStart
                    )
                    
                    TimePickerRow(
                        title: "End Time",
                        time: viewModel.quietHoursEndTime,
                        onChange: viewModel.updateQuietHoursEnd
                    )
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.white.opacity(0.9))
                        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
                )
                
                if viewModel.isCurrentlyInQuietHours {
                    HStack {
                        Image(systemName: "moon.fill")
                            .foregroundColor(.purple)
                        
                        Text("Quiet hours are currently active")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.purple)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.purple.opacity(0.1))
                    )
                }
                
                Spacer()
            }
            .padding()
            .background(Color.mainAppGradient.ignoresSafeArea())
            .navigationTitle("Quiet Hours")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.brandDarkBlue)
                }
            }
        }
    }
}

// MARK: - Time Picker Row
private struct TimePickerRow: View {
    let title: String
    let time: Date
    let onChange: (Date) -> Void
    
    var body: some View {
        HStack {
            Text(title)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Spacer()
            
            DatePicker(
                "",
                selection: Binding(
                    get: { time },
                    set: onChange
                ),
                displayedComponents: .hourAndMinute
            )
            .labelsHidden()
        }
    }
}

// MARK: - Preview
struct NotificationSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationSettingsView()
    }
}