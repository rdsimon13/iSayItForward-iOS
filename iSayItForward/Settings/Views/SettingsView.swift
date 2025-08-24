import SwiftUI
import FirebaseAuth

// MARK: - Main settings view
struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.mainAppGradient.ignoresSafeArea()
                
                if viewModel.isLoading {
                    LoadingView()
                } else {
                    settingsContent
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color.brandDarkBlue)
                }
            }
            .alert("Settings Error", isPresented: $viewModel.showingError) {
                Button("OK") {
                    viewModel.dismissError()
                }
            } message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred")
            }
            .refreshable {
                viewModel.refreshSettings()
            }
        }
    }
    
    // MARK: - Settings content
    private var settingsContent: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // User profile section
                userProfileSection
                
                // Settings sections
                settingsSections
                
                // Sync status
                syncStatusSection
                
                // Quick actions
                quickActionsSection
                
                Spacer(minLength: 50)
            }
            .padding()
        }
    }
    
    // MARK: - User profile section
    private var userProfileSection: some View {
        VStack(spacing: 16) {
            // Profile image and name
            HStack(spacing: 16) {
                profileImage
                
                VStack(alignment: .leading, spacing: 4) {
                    if let user = viewModel.currentUser {
                        Text(user.displayName ?? "User")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        Text(user.email ?? "")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Profile completion
                    profileCompletionBar
                }
                
                Spacer()
            }
            
            Divider()
        }
        .padding()
        .background(.white.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .foregroundColor(Color.brandDarkBlue)
        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
    }
    
    private var profileImage: some View {
        ZStack {
            Circle()
                .fill(Color.brandDarkBlue.opacity(0.1))
                .frame(width: 60, height: 60)
            
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .foregroundColor(Color.brandDarkBlue)
        }
    }
    
    private var profileCompletionBar: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Profile Completion")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(viewModel.profileCompletionPercentage * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(Color.brandYellow)
            }
            
            ProgressView(value: viewModel.profileCompletionPercentage)
                .progressViewStyle(LinearProgressViewStyle(tint: Color.brandYellow))
                .scaleEffect(y: 0.8)
        }
    }
    
    // MARK: - Settings sections
    private var settingsSections: some View {
        VStack(spacing: 16) {
            // Profile settings
            NavigationLink(destination: ProfileSettingsView(viewModel: viewModel.profileViewModel)) {
                SettingsRowView(
                    icon: "person.circle.fill",
                    title: "Profile",
                    subtitle: "Personal information and bio",
                    badge: viewModel.profileCompletionPercentage < 1.0 ? "Incomplete" : nil,
                    badgeColor: Color.brandYellow
                )
            }
            
            // Privacy settings
            NavigationLink(destination: PrivacySettingsView(viewModel: viewModel.privacyViewModel)) {
                SettingsRowView(
                    icon: "lock.circle.fill",
                    title: "Privacy & Security",
                    subtitle: "Control your data and visibility",
                    badge: viewModel.privacyViewModel.privacyLevel,
                    badgeColor: privacyLevelColor
                )
            }
            
            // Notification settings
            NavigationLink(destination: NotificationSettingsView(viewModel: viewModel.notificationViewModel)) {
                SettingsRowView(
                    icon: "bell.circle.fill",
                    title: "Notifications",
                    subtitle: viewModel.notificationViewModel.notificationSummary,
                    badge: viewModel.hasNotificationPermissions ? nil : "Setup Required",
                    badgeColor: .red
                )
            }
            
            // Appearance settings
            NavigationLink(destination: AppearanceSettingsView(viewModel: viewModel.appearanceViewModel)) {
                SettingsRowView(
                    icon: "paintbrush.pointed.fill",
                    title: "Appearance",
                    subtitle: "Theme, text size, and accessibility",
                    badge: viewModel.appearanceViewModel.theme.displayName,
                    badgeColor: Color.brandDarkBlue
                )
            }
        }
    }
    
    // MARK: - Sync status section
    private var syncStatusSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "icloud.fill")
                    .foregroundColor(viewModel.isDataSyncEnabled ? .green : .gray)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Settings Sync")
                        .font(.headline)
                    
                    Text("Last synced: \(viewModel.formattedLastSync)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
        }
        .padding()
        .background(.white.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .foregroundColor(Color.brandDarkBlue)
        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
    }
    
    // MARK: - Quick actions section
    private var quickActionsSection: some View {
        VStack(spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                // Toggle notifications
                QuickActionButton(
                    icon: "bell.slash.fill",
                    title: "Notifications",
                    isActive: viewModel.notificationViewModel.pushNotificationsEnabled
                ) {
                    Task {
                        await viewModel.toggleNotifications()
                    }
                }
                
                // Toggle dark mode
                QuickActionButton(
                    icon: "moon.fill",
                    title: "Dark Mode",
                    isActive: viewModel.appearanceViewModel.theme == .dark
                ) {
                    Task {
                        await viewModel.toggleDarkMode()
                    }
                }
                
                // Toggle private profile
                QuickActionButton(
                    icon: "eye.slash.fill",
                    title: "Private",
                    isActive: viewModel.privacyViewModel.profileVisibility == .privateProfile
                ) {
                    Task {
                        await viewModel.togglePrivateProfile()
                    }
                }
            }
        }
    }
    
    // MARK: - Computed properties
    private var privacyLevelColor: Color {
        switch viewModel.privacyViewModel.privacyLevel {
        case "Open": return .green
        case "Balanced": return .orange
        case "High Privacy": return .red
        case "Maximum Privacy": return .purple
        default: return Color.brandDarkBlue
        }
    }
}

// MARK: - Settings row view
private struct SettingsRowView: View {
    let icon: String
    let title: String
    let subtitle: String
    let badge: String?
    let badgeColor: Color
    
    init(icon: String, title: String, subtitle: String, badge: String? = nil, badgeColor: Color = Color.brandDarkBlue) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.badge = badge
        self.badgeColor = badgeColor
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Color.brandYellow)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            if let badge = badge {
                Text(badge)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(badgeColor.opacity(0.2))
                    .foregroundColor(badgeColor)
                    .clipShape(Capsule())
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(.white.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .foregroundColor(Color.brandDarkBlue)
        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
    }
}

// MARK: - Quick action button
private struct QuickActionButton: View {
    let icon: String
    let title: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isActive ? Color.brandYellow : .white)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isActive ? Color.brandDarkBlue : Color.brandDarkBlue.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 3, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Loading view
private struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(Color.brandYellow)
            
            Text("Loading Settings...")
                .font(.headline)
                .foregroundColor(.white)
        }
    }
}

// MARK: - Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}