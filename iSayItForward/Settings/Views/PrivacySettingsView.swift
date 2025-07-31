import SwiftUI

// MARK: - Privacy settings view
struct PrivacySettingsView: View {
    @ObservedObject var viewModel: PrivacySettingsViewModel
    @State private var showingPresetOptions = false
    
    var body: some View {
        ZStack {
            Color.mainAppGradient.ignoresSafeArea()
            
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Privacy overview
                    privacyOverviewSection
                    
                    // Profile visibility
                    profileVisibilitySection
                    
                    // Communication settings
                    communicationSection
                    
                    // Data sharing
                    dataSharingSection
                    
                    // Blocked users
                    blockedUsersSection
                    
                    // Quick presets
                    presetsSection
                    
                    // Data management
                    dataManagementSection
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
        }
        .navigationTitle("Privacy & Security")
        .navigationBarTitleDisplayMode(.large)
        .actionSheet(isPresented: $showingPresetOptions) {
            ActionSheet(
                title: Text("Privacy Presets"),
                message: Text("Choose a privacy level that suits your needs"),
                buttons: [
                    .default(Text("Open Profile")) {
                        Task { await viewModel.applyOpenPrivacySettings() }
                    },
                    .default(Text("Balanced Privacy")) {
                        Task { await viewModel.applyBalancedPrivacySettings() }
                    },
                    .default(Text("Maximum Privacy")) {
                        Task { await viewModel.applyMaxPrivacySettings() }
                    },
                    .cancel()
                ]
            )
        }
        .sheet(isPresented: $viewModel.showingBlockedUsers) {
            BlockedUsersView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showingDataExport) {
            DataExportView(viewModel: viewModel)
        }
    }
    
    // MARK: - Privacy overview section
    private var privacyOverviewSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Privacy Level")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(viewModel.privacyLevel)
                        .font(.title2)
                        .fontWeight(.heavy)
                        .foregroundColor(privacyLevelColor)
                }
                
                Spacer()
                
                Image(systemName: privacyLevelIcon)
                    .font(.largeTitle)
                    .foregroundColor(privacyLevelColor)
            }
            
            Text(viewModel.dataCollectionSummary)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(.white.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .foregroundColor(Color.brandDarkBlue)
        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
    }
    
    // MARK: - Profile visibility section
    private var profileVisibilitySection: some View {
        SettingsCardView(title: "Profile Visibility") {
            VStack(spacing: 16) {
                Text("Control who can see your profile information")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                ForEach(ProfileVisibility.allCases, id: \.self) { visibility in
                    PrivacyOptionRow(
                        title: visibility.displayName,
                        description: profileVisibilityDescription(visibility),
                        isSelected: viewModel.profileVisibility == visibility
                    ) {
                        Task {
                            await viewModel.setProfileVisibility(visibility)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Communication section
    private var communicationSection: Some View {
        SettingsCardView(title: "Communication") {
            VStack(spacing: 16) {
                ToggleRow(
                    title: "Allow Direct Messages",
                    description: "Let others send you direct messages",
                    isOn: $viewModel.allowDirectMessages
                ) {
                    Task { await viewModel.saveChanges() }
                }
                
                ToggleRow(
                    title: "Allow SIFs from Strangers",
                    description: "Receive SIFs from people you don't follow",
                    isOn: $viewModel.allowSIFFromStrangers
                ) {
                    Task { await viewModel.saveChanges() }
                }
                
                ToggleRow(
                    title: "Show Online Status",
                    description: "Let others see when you're active",
                    isOn: $viewModel.showOnlineStatus
                ) {
                    Task { await viewModel.saveChanges() }
                }
                
                ToggleRow(
                    title: "Share Activity Status",
                    description: "Show your recent activity to friends",
                    isOn: $viewModel.shareActivityStatus
                ) {
                    Task { await viewModel.saveChanges() }
                }
            }
        }
    }
    
    // MARK: - Data sharing section
    private var dataSharingSection: some View {
        SettingsCardView(title: "Data Sharing") {
            VStack(spacing: 16) {
                ToggleRow(
                    title: "Allow Data Collection",
                    description: "Help improve the app with usage data",
                    isOn: $viewModel.allowDataCollection
                ) {
                    Task { await viewModel.saveChanges() }
                }
                
                ToggleRow(
                    title: "Analytics",
                    description: "Share anonymous analytics data",
                    isOn: $viewModel.allowAnalytics
                ) {
                    Task { await viewModel.saveChanges() }
                }
                
                ToggleRow(
                    title: "Location Sharing",
                    description: "Share your location for location-based features",
                    isOn: $viewModel.allowLocationSharing
                ) {
                    Task { await viewModel.saveChanges() }
                }
                
                ToggleRow(
                    title: "Contact Sync",
                    description: "Sync contacts to find friends",
                    isOn: $viewModel.allowContactSync
                ) {
                    Task { await viewModel.saveChanges() }
                }
            }
        }
    }
    
    // MARK: - Blocked users section
    private var blockedUsersSection: some View {
        SettingsCardView(title: "Blocked Users") {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(viewModel.blockedUsersCount) blocked users")
                            .font(.headline)
                        
                        if viewModel.hasBlockedUsers {
                            Text("Manage your blocked users list")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("No blocked users")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    if viewModel.hasBlockedUsers {
                        Button("Manage") {
                            viewModel.showingBlockedUsers = true
                        }
                        .buttonStyle(SecondaryActionButtonStyle())
                    }
                }
                
                if viewModel.hasBlockedUsers {
                    HStack {
                        Button("Clear All") {
                            Task {
                                await viewModel.clearAllBlockedUsers()
                            }
                        }
                        .foregroundColor(.red)
                        .font(.caption)
                        
                        Spacer()
                    }
                }
            }
        }
    }
    
    // MARK: - Presets section
    private var presetsSection: some View {
        VStack(spacing: 12) {
            Text("Quick Privacy Presets")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(.white)
            
            Button("Choose Privacy Level") {
                showingPresetOptions = true
            }
            .buttonStyle(PrimaryActionButtonStyle())
        }
    }
    
    // MARK: - Data management section
    private var dataManagementSection: some View {
        SettingsCardView(title: "Data Management") {
            VStack(spacing: 16) {
                Button("Export My Data") {
                    Task {
                        await viewModel.exportUserData()
                    }
                }
                .buttonStyle(SecondaryActionButtonStyle())
                .disabled(viewModel.isExportingData)
                
                if viewModel.isExportingData {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Preparing export...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Divider()
                
                Button("Delete All Data") {
                    Task {
                        await viewModel.deleteAllUserData()
                    }
                }
                .foregroundColor(.red)
                .font(.headline)
                
                Text("Warning: This action cannot be undone")
                    .font(.caption)
                    .foregroundColor(.red.opacity(0.8))
            }
        }
    }
    
    // MARK: - Helper methods
    private func profileVisibilityDescription(_ visibility: ProfileVisibility) -> String {
        switch visibility {
        case .publicProfile:
            return "Anyone can see your profile"
        case .friendsOnly:
            return "Only people you follow can see your profile"
        case .privateProfile:
            return "Your profile is completely private"
        }
    }
    
    private var privacyLevelColor: Color {
        switch viewModel.privacyLevel {
        case "Open": return .green
        case "Balanced": return .orange
        case "High Privacy": return .red
        case "Maximum Privacy": return .purple
        default: return Color.brandDarkBlue
        }
    }
    
    private var privacyLevelIcon: String {
        switch viewModel.privacyLevel {
        case "Open": return "eye.fill"
        case "Balanced": return "eye.slash.fill"
        case "High Privacy": return "lock.fill"
        case "Maximum Privacy": return "lock.shield.fill"
        default: return "shield.fill"
        }
    }
}

// MARK: - Privacy option row
private struct PrivacyOptionRow: View {
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

// MARK: - Toggle row
private struct ToggleRow: View {
    let title: String
    let description: String
    @Binding var isOn: Bool
    let onChange: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: Color.brandYellow))
                .onChange(of: isOn) { _ in
                    onChange()
                }
        }
    }
}

// MARK: - Blocked users view placeholder
private struct BlockedUsersView: View {
    @ObservedObject var viewModel: PrivacySettingsViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.blockedUsers, id: \.self) { userUID in
                    HStack {
                        Text("User \(userUID)")
                        Spacer()
                        Button("Unblock") {
                            Task {
                                await viewModel.unblockUser(userUID)
                            }
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
            .navigationTitle("Blocked Users")
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
}

// MARK: - Data export view placeholder
private struct DataExportView: View {
    @ObservedObject var viewModel: PrivacySettingsViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Data Export Complete")
                    .font(.title)
                
                Text("Your data has been prepared for export. Check your email for download instructions.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(PrimaryActionButtonStyle())
            }
            .padding()
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Preview
struct PrivacySettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PrivacySettingsView(viewModel: PrivacySettingsViewModel())
        }
    }
}