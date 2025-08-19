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
                // FIXED: Use the new vibrant gradient
                Theme.vibrantGradient.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // --- Header ---
                        Text("SIF Settings")
                            .font(.largeTitle.weight(.bold))
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        // --- Settings Sections ---
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
                        
                        SettingsSection(title: "Privacy") {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Default SIF Privacy")
                                    .font(.headline)
                                    .fontWeight(.medium)
                                
                                Text("Choose the default privacy setting for new SIFs")
                                    .font(.caption)
                                    .opacity(0.8)
                                
                                Picker("Default Privacy", selection: $defaultPrivacy) {
                                    ForEach(privacyOptions, id: \.self) { option in
                                        Text(option)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .colorScheme(.dark) // Ensures the picker text is white
                            }
                            .foregroundColor(.white)
                            .padding()
                            .frostedGlass()
                        }
                        
                        SettingsSection(title: "Signatures") {
                            SettingsToggle(
                                title: "Auto-save Signatures",
                                description: "Automatically save signatures for future use",
                                isOn: $autoSaveSignatures
                            )
                            
                            NavigationLink(destination: ProfileView()) {
                                HStack {
                                    Image(systemName: "signature")
                                    Text("Manage Signatures")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                }
                                .font(.headline)
                            }
                            .foregroundColor(.white)
                            .padding()
                            .frostedGlass()
                        }
                        
                        Spacer()
                    }
                    .padding()
                }
                .navigationTitle("Settings")
                .navigationBarHidden(true)
            }
        }
    }
}

// MARK: - Settings Section (UI Transformed)
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
                .font(.title2.weight(.bold))
                .foregroundColor(.white)
            
            content
        }
    }
}

// MARK: - Settings Toggle (UI Transformed)
private struct SettingsToggle: View {
    let title: String
    let description: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .opacity(0.8)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .tint(Theme.darkTeal) // Use a tint that shows up well
        }
        .foregroundColor(.white)
        .padding()
        .frostedGlass()
    }
}

struct SIFSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SIFSettingsView().preferredColorScheme(.dark)
    }
}
