import SwiftUI

struct PrivacySettingsView: View {
    @StateObject private var userDataManager = UserDataManager()
    @State private var privacySettings: PrivacySettings
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var hasChanges = false
    
    init(initialSettings: PrivacySettings = PrivacySettings()) {
        _privacySettings = State(initialValue: initialSettings)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.mainAppGradient.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                            
                            Text("Privacy Settings")
                                .font(.title2.weight(.bold))
                                .foregroundColor(.white)
                            
                            Text("Control your privacy and visibility")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.top)
                        
                        // Profile Visibility
                        SettingsSection(title: "Profile Visibility") {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Who can see your profile")
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(Color.brandDarkBlue)
                                
                                ForEach(ProfileVisibility.allCases, id: \.self) { visibility in
                                    VisibilityOption(
                                        visibility: visibility,
                                        isSelected: privacySettings.profileVisibility == visibility,
                                        onSelect: {
                                            privacySettings.profileVisibility = visibility
                                            markAsChanged()
                                        }
                                    )
                                }
                            }
                            .padding()
                        }
                        
                        // Messaging Settings
                        SettingsSection(title: "Messaging") {
                            PrivacyToggle(
                                title: "Allow Messages from Strangers",
                                subtitle: "Let people who aren't your friends send you SIFs",
                                isOn: $privacySettings.allowsMessagesFromStrangers,
                                onChange: markAsChanged
                            )
                        }
                        
                        // Online Status
                        SettingsSection(title: "Online Status") {
                            PrivacyToggle(
                                title: "Show Online Status",
                                subtitle: "Let others see when you're online",
                                isOn: $privacySettings.showOnlineStatus,
                                onChange: markAsChanged
                            )
                            
                            PrivacyToggle(
                                title: "Show Last Seen",
                                subtitle: "Let others see when you were last active",
                                isOn: $privacySettings.showLastSeen,
                                onChange: markAsChanged
                            )
                        }
                        
                        // Profile Image
                        SettingsSection(title: "Profile Image") {
                            PrivacyToggle(
                                title: "Allow Profile Image Download",
                                subtitle: "Let others save your profile image",
                                isOn: $privacySettings.allowProfileImageDownload,
                                onChange: markAsChanged
                            )
                        }
                        
                        // Privacy Information
                        PrivacyInfoSection()
                        
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
            .navigationTitle("Privacy")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Privacy Settings", isPresented: $showingAlert) {
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
            privacySettings = currentUser.privacySettings
        }
    }
    
    private func saveSettings() async {
        await userDataManager.updatePrivacySettings(privacySettings)
        
        if let error = userDataManager.errorMessage {
            alertMessage = error
            showingAlert = true
        } else {
            alertMessage = "Privacy settings saved successfully!"
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

private struct PrivacyToggle: View {
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

private struct VisibilityOption: View {
    let visibility: ProfileVisibility
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(visibility.displayName)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(Color.brandDarkBlue)
                    
                    Text(visibilityDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.brandDarkBlue)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var visibilityDescription: String {
        switch visibility {
        case .everyone:
            return "Anyone can see your profile"
        case .friendsOnly:
            return "Only your friends can see your profile"
        case .nobody:
            return "Your profile is completely private"
        }
    }
}

private struct PrivacyInfoSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Privacy Information")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(
                    icon: "info.circle.fill",
                    text: "Your privacy settings help control how others interact with you on iSayItForward."
                )
                
                InfoRow(
                    icon: "shield.fill",
                    text: "We never share your personal information with third parties without your consent."
                )
                
                InfoRow(
                    icon: "lock.fill",
                    text: "You can change these settings at any time."
                )
            }
            .padding()
            .background(.white.opacity(0.85))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
        }
    }
}

private struct InfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color.brandDarkBlue)
                .frame(width: 20)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
    }
}

#Preview {
    PrivacySettingsView()
}