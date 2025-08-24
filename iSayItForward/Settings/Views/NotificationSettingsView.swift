import SwiftUI

// MARK: - Notification settings view
struct NotificationSettingsView: View {
    @ObservedObject var viewModel: NotificationSettingsViewModel
    @State private var showingPresetOptions = false
    
    var body: some View {
        ZStack {
            Color.mainAppGradient.ignoresSafeArea()
            
            ScrollView {
                LazyVStack(spacing: 20) {
                    // System permissions section
                    if viewModel.needsSystemPermissions {
                        systemPermissionsSection
                    }
                    
                    // Notification overview
                    notificationOverviewSection
                    
                    // General notifications
                    generalNotificationsSection
                    
                    // SIF notifications
                    sifNotificationsSection
                    
                    // Social notifications
                    socialNotificationsSection
                    
                    // Marketing notifications
                    marketingNotificationsSection
                    
                    // Frequency settings
                    frequencySection
                    
                    // Quiet hours
                    quietHoursSection
                    
                    // Quick presets
                    presetsSection
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            viewModel.checkNotificationStatus()
        }
        .actionSheet(isPresented: $showingPresetOptions) {
            ActionSheet(
                title: Text("Notification Presets"),
                message: Text("Choose a notification level"),
                buttons: [
                    .default(Text("All Notifications")) {
                        Task { await viewModel.applyAllNotifications() }
                    },
                    .default(Text("Standard")) {
                        Task { await viewModel.applyStandardNotifications() }
                    },
                    .default(Text("Minimal")) {
                        Task { await viewModel.applyMinimalNotifications() }
                    },
                    .cancel()
                ]
            )
        }
    }
    
    // MARK: - System permissions section
    private var systemPermissionsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notification Permissions Required")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text("Enable notifications in system settings to receive alerts")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                if viewModel.systemNotificationStatus == .notDetermined {
                    Button("Enable Notifications") {
                        Task {
                            await viewModel.requestNotificationPermissions()
                        }
                    }
                    .buttonStyle(PrimaryActionButtonStyle())
                    .disabled(viewModel.isRequestingPermissions)
                } else {
                    Button("Open Settings") {
                        viewModel.openSystemSettings()
                    }
                    .buttonStyle(SecondaryActionButtonStyle())
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
    }
    
    // MARK: - Notification overview section
    private var notificationOverviewSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notification Status")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(viewModel.notificationSummary)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Toggle All") {
                    Task {
                        await viewModel.toggleAllNotifications()
                    }
                }
                .buttonStyle(SecondaryActionButtonStyle())
                .frame(width: 100)
            }
        }
        .padding()
        .background(.white.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .foregroundColor(Color.brandDarkBlue)
        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
    }
    
    // MARK: - General notifications section
    private var generalNotificationsSection: some View {
        SettingsCardView(title: "General Notifications") {
            VStack(spacing: 16) {
                ToggleRow(
                    title: "Push Notifications",
                    description: "Receive notifications on your device",
                    isOn: $viewModel.pushNotificationsEnabled
                ) {
                    Task { await viewModel.saveChanges() }
                }
                
                ToggleRow(
                    title: "Email Notifications",
                    description: "Receive notifications via email",
                    isOn: $viewModel.emailNotificationsEnabled
                ) {
                    Task { await viewModel.saveChanges() }
                }
                
                ToggleRow(
                    title: "In-App Alerts",
                    description: "Show alerts while using the app",
                    isOn: $viewModel.inAppAlertsEnabled
                ) {
                    Task { await viewModel.saveChanges() }
                }
            }
        }
    }
    
    // MARK: - SIF notifications section
    private var sifNotificationsSection: some View {
        SettingsCardView(title: "SIF Notifications") {
            VStack(spacing: 16) {
                ToggleRow(
                    title: "New SIF Received",
                    description: "When someone sends you a SIF",
                    isOn: $viewModel.newSIFNotifications
                ) {
                    Task { await viewModel.saveChanges() }
                }
                
                ToggleRow(
                    title: "SIF Delivered",
                    description: "When your SIF is successfully delivered",
                    isOn: $viewModel.sifDeliveredNotifications
                ) {
                    Task { await viewModel.saveChanges() }
                }
                
                ToggleRow(
                    title: "SIF Opened",
                    description: "When someone opens your SIF",
                    isOn: $viewModel.sifOpenedNotifications
                ) {
                    Task { await viewModel.saveChanges() }
                }
                
                ToggleRow(
                    title: "Template Updates",
                    description: "When new templates are available",
                    isOn: $viewModel.templateUpdateNotifications
                ) {
                    Task { await viewModel.saveChanges() }
                }
            }
        }
    }
    
    // MARK: - Social notifications section
    private var socialNotificationsSection: some View {
        SettingsCardView(title: "Social Notifications") {
            VStack(spacing: 16) {
                ToggleRow(
                    title: "Friend Requests",
                    description: "When someone sends you a friend request",
                    isOn: $viewModel.friendRequestNotifications
                ) {
                    Task { await viewModel.saveChanges() }
                }
                
                ToggleRow(
                    title: "Messages",
                    description: "When you receive a direct message",
                    isOn: $viewModel.messageNotifications
                ) {
                    Task { await viewModel.saveChanges() }
                }
                
                ToggleRow(
                    title: "Mentions",
                    description: "When someone mentions you",
                    isOn: $viewModel.mentionNotifications
                ) {
                    Task { await viewModel.saveChanges() }
                }
            }
        }
    }
    
    // MARK: - Marketing notifications section
    private var marketingNotificationsSection: some View {
        SettingsCardView(title: "Updates & Marketing") {
            VStack(spacing: 16) {
                ToggleRow(
                    title: "Marketing Emails",
                    description: "Promotional content and offers",
                    isOn: $viewModel.marketingEmails
                ) {
                    Task { await viewModel.saveChanges() }
                }
                
                ToggleRow(
                    title: "Product Updates",
                    description: "New features and improvements",
                    isOn: $viewModel.productUpdates
                ) {
                    Task { await viewModel.saveChanges() }
                }
                
                ToggleRow(
                    title: "Weekly Digest",
                    description: "Summary of your week's activity",
                    isOn: $viewModel.weeklyDigest
                ) {
                    Task { await viewModel.saveChanges() }
                }
            }
        }
    }
    
    // MARK: - Frequency section
    private var frequencySection: some View {
        SettingsCardView(title: "Notification Frequency") {
            VStack(spacing: 16) {
                Text("How often would you like to receive notifications?")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                ForEach(NotificationFrequency.allCases, id: \.self) { frequency in
                    FrequencyOptionRow(
                        title: frequency.displayName,
                        description: frequencyDescription(frequency),
                        isSelected: viewModel.notificationFrequency == frequency
                    ) {
                        Task {
                            await viewModel.setNotificationFrequency(frequency)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Quiet hours section
    private var quietHoursSection: some View {
        SettingsCardView(title: "Quiet Hours") {
            VStack(spacing: 16) {
                ToggleRow(
                    title: "Enable Quiet Hours",
                    description: viewModel.quietHoursSummary,
                    isOn: $viewModel.quietHoursEnabled
                ) {
                    Task { await viewModel.toggleQuietHours() }
                }
                
                if viewModel.quietHoursEnabled {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Start Time")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            TextField("22:00", text: $viewModel.quietHoursStart)
                                .textFieldStyle(PillTextFieldStyle())
                                .keyboardType(.numbersAndPunctuation)
                                .onSubmit {
                                    Task {
                                        await viewModel.updateQuietHours(
                                            start: viewModel.quietHoursStart,
                                            end: viewModel.quietHoursEnd
                                        )
                                    }
                                }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("End Time")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            TextField("08:00", text: $viewModel.quietHoursEnd)
                                .textFieldStyle(PillTextFieldStyle())
                                .keyboardType(.numbersAndPunctuation)
                                .onSubmit {
                                    Task {
                                        await viewModel.updateQuietHours(
                                            start: viewModel.quietHoursStart,
                                            end: viewModel.quietHoursEnd
                                        )
                                    }
                                }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Presets section
    private var presetsSection: some View {
        VStack(spacing: 12) {
            Text("Quick Notification Presets")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(.white)
            
            Button("Choose Notification Level") {
                showingPresetOptions = true
            }
            .buttonStyle(PrimaryActionButtonStyle())
        }
    }
    
    // MARK: - Helper methods
    private func frequencyDescription(_ frequency: NotificationFrequency) -> String {
        switch frequency {
        case .immediate:
            return "Get notified immediately as things happen"
        case .normal:
            return "Standard notification timing"
        case .digest:
            return "Receive a daily summary of notifications"
        case .minimal:
            return "Only essential notifications"
        }
    }
}

// MARK: - Frequency option row
private struct FrequencyOptionRow: View {
    let title: String
    let description: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? Color.brandYellow : .gray)
            }
            .padding()
            .background(isSelected ? Color.brandYellow.opacity(0.1) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.brandYellow : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .foregroundColor(Color.brandDarkBlue)
    }
}

// MARK: - Preview
struct NotificationSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            NotificationSettingsView(viewModel: NotificationSettingsViewModel())
        }
    }
}