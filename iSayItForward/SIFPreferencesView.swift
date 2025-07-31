import SwiftUI

struct SIFPreferencesView: View {
    @ObservedObject var settingsManager: SIFSettingsManager
    @Environment(\.presentationMode) var presentationMode
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        ZStack {
            Color.mainAppGradient.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack {
                        Text("SIF Preferences")
                            .font(.largeTitle.weight(.bold))
                            .foregroundColor(.white)
                            .padding(.top)
                        
                        Text("Customize your SIF experience")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    // Default SIF Settings Section
                    PreferencesSectionView(title: "Default SIF Settings", iconName: "doc.text") {
                        VStack(spacing: 16) {
                            PreferencesTextField(
                                title: "Default Subject",
                                text: $settingsManager.preferences.defaultSubject,
                                placeholder: "Enter default subject..."
                            )
                            
                            PreferencesTextField(
                                title: "Default Message",
                                text: $settingsManager.preferences.defaultMessage,
                                placeholder: "Enter default message...",
                                isMultiline: true
                            )
                            
                            PreferencesToggle(
                                title: "Auto-save drafts",
                                description: "Automatically save SIF drafts as you type",
                                isOn: $settingsManager.preferences.autoSave
                            )
                            
                            PreferencesToggle(
                                title: "Use templates",
                                description: "Show template suggestions when creating SIFs",
                                isOn: $settingsManager.preferences.useTemplates
                            )
                        }
                    }
                    
                    // Notification Preferences Section
                    PreferencesSectionView(title: "Notifications", iconName: "bell") {
                        VStack(spacing: 16) {
                            PreferencesToggle(
                                title: "Enable notifications",
                                description: "Receive app notifications",
                                isOn: $settingsManager.preferences.notificationsEnabled
                            )
                            
                            PreferencesToggle(
                                title: "Scheduled reminders",
                                description: "Get reminded about scheduled SIFs",
                                isOn: $settingsManager.preferences.scheduledReminders
                            )
                            .disabled(!settingsManager.preferences.notificationsEnabled)
                            
                            PreferencesToggle(
                                title: "Delivery confirmations",
                                description: "Notify when SIFs are delivered",
                                isOn: $settingsManager.preferences.deliveryConfirmations
                            )
                            .disabled(!settingsManager.preferences.notificationsEnabled)
                        }
                    }
                    
                    // Privacy Settings Section
                    PreferencesSectionView(title: "Privacy", iconName: "lock.shield") {
                        VStack(spacing: 16) {
                            PreferencesToggle(
                                title: "Share statistics",
                                description: "Share anonymous usage statistics to help improve the app",
                                isOn: $settingsManager.preferences.shareStatistics
                            )
                            
                            PreferencesToggle(
                                title: "Anonymous feedback",
                                description: "Allow anonymous feedback collection",
                                isOn: $settingsManager.preferences.allowAnonymousFeedback
                            )
                        }
                    }
                    
                    // Scheduling Preferences Section
                    PreferencesSectionView(title: "Scheduling", iconName: "calendar.clock") {
                        VStack(spacing: 16) {
                            PreferencesTimePicker(
                                title: "Default schedule time",
                                time: $settingsManager.preferences.defaultScheduleTime
                            )
                            
                            PreferencesToggle(
                                title: "Weekend scheduling",
                                description: "Allow scheduling SIFs on weekends",
                                isOn: $settingsManager.preferences.weekendScheduling
                            )
                        }
                    }
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button("Save Preferences") {
                            savePreferences()
                        }
                        .buttonStyle(PrimaryActionButtonStyle())
                        
                        Button("Reset to Defaults") {
                            settingsManager.resetToDefaults()
                            alertMessage = "Preferences reset to defaults"
                            showingAlert = true
                        }
                        .buttonStyle(SecondaryActionButtonStyle())
                    }
                    .padding(.top)
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Preferences"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    private func savePreferences() {
        let validationErrors = settingsManager.validatePreferences()
        
        if validationErrors.isEmpty {
            settingsManager.savePreferences()
            alertMessage = "Preferences saved successfully!"
            showingAlert = true
        } else {
            alertMessage = "Please fix the following errors:\n" + validationErrors.joined(separator: "\n")
            showingAlert = true
        }
    }
}

// MARK: - Supporting Views
private struct PreferencesSectionView<Content: View>: View {
    let title: String
    let iconName: String
    let content: Content
    
    init(title: String, iconName: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.iconName = iconName
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: iconName)
                    .foregroundColor(Color.brandDarkBlue)
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundColor(Color.brandDarkBlue)
                Spacer()
            }
            
            content
        }
        .padding(20)
        .background(.white.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
    }
}

private struct PreferencesTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var isMultiline: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundColor(Color.brandDarkBlue)
            
            if isMultiline {
                TextField(placeholder, text: $text, axis: .vertical)
                    .lineLimit(3...6)
                    .textFieldStyle(PillTextFieldStyle())
            } else {
                TextField(placeholder, text: $text)
                    .textFieldStyle(PillTextFieldStyle())
            }
        }
    }
}

private struct PreferencesToggle: View {
    let title: String
    let description: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(Color.brandDarkBlue)
                Text(description)
                    .font(.caption)
                    .foregroundColor(Color.brandDarkBlue.opacity(0.7))
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: Color.brandYellow))
        }
    }
}

private struct PreferencesTimePicker: View {
    let title: String
    @Binding var time: String
    @State private var selectedTime = Date()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundColor(Color.brandDarkBlue)
            
            DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .onChange(of: selectedTime) { newTime in
                    let formatter = DateFormatter()
                    formatter.dateFormat = "HH:mm"
                    time = formatter.string(from: newTime)
                }
                .onAppear {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "HH:mm"
                    if let date = formatter.date(from: time) {
                        selectedTime = date
                    }
                }
        }
    }
}

struct SIFPreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SIFPreferencesView(settingsManager: SIFSettingsManager())
        }
    }
}