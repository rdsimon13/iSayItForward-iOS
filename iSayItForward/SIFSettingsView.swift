import SwiftUI

struct SIFSettingsView: View {
    @State private var enableNotifications = true
    @State private var enableScheduleReminders = true
    @State private var defaultPrivacy = "Private"
    @State private var autoSaveSignatures = true
    
    let privacyOptions = ["Private", "Public", "Friends Only"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.mainAppGradient.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("SIF Settings")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(Color.brandDarkBlue)
                            
                            Text("Customize your SIF preferences and account options")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(.white.opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.1), radius: 8, y: 3)
                        
                        // Notification Settings
                        SettingsSection(title: "Notifications") {
                            SettingsToggle(
                                title: "Enable Notifications",
                                description: "Receive notifications for SIF deliveries and reminders",
                                isOn: $enableNotifications
                            )
                            
                            SettingsToggle(
                                title: "Schedule Reminders",
                                description: "Get reminded before scheduled SIFs are sent",
                                isOn: $enableScheduleReminders
                            )
                        }
                        
                        // Privacy Settings
                        SettingsSection(title: "Privacy") {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Default SIF Privacy")
                                    .font(.headline)
                                    .fontWeight(.medium)
                                
                                Text("Choose the default privacy setting for new SIFs")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Picker("Default Privacy", selection: $defaultPrivacy) {
                                    ForEach(privacyOptions, id: \.self) { option in
                                        Text(option)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                        }
                        
                        // Signature Settings
                        SettingsSection(title: "Signatures") {
                            SettingsToggle(
                                title: "Auto-save Signatures",
                                description: "Automatically save signatures for future use",
                                isOn: $autoSaveSignatures
                            )
                            
                            NavigationLink(destination: ProfileView()) {
                                HStack {
                                    Image(systemName: "signature")
                                        .font(.title2)
                                        .foregroundColor(Color.brandDarkBlue)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Manage Signatures")
                                            .font(.headline)
                                            .fontWeight(.medium)
                                        
                                        Text("View and manage your saved signatures")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(.white.opacity(0.7))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .foregroundColor(Color.brandDarkBlue)
                        }
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Settings Section
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
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color.brandDarkBlue)
            
            content
        }
        .padding()
        .background(.white.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 3)
    }
}

// MARK: - Settings Toggle
private struct SettingsToggle: View {
    let title: String
    let description: String
    @Binding var isOn: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $isOn)
                    .tint(Color.brandDarkBlue)
            }
        }
        .padding()
        .background(.white.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct SIFSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SIFSettingsView()
    }
}