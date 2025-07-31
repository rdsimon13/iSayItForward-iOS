import SwiftUI

struct ContactSettingsView: View {
    @ObservedObject var contactManager: ContactManager
    @State private var cloudSyncEnabled = true
    @State private var showingSyncAlert = false
    @State private var syncAction: SyncAction = .toCloud
    @State private var autoSync = true
    @State private var encryptSensitiveData = true
    @State private var allowContactImport = true
    
    enum SyncAction {
        case toCloud
        case fromCloud
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Cloud Synchronization") {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Cloud Sync")
                                .font(.headline)
                            Text("Sync contacts across devices")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if contactManager.isSyncing {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Toggle("", isOn: $cloudSyncEnabled)
                        }
                    }
                    
                    if cloudSyncEnabled {
                        Toggle("Auto Sync", isOn: $autoSync)
                        
                        Button("Sync to Cloud") {
                            syncAction = .toCloud
                            showingSyncAlert = true
                        }
                        
                        Button("Sync from Cloud") {
                            syncAction = .fromCloud
                            showingSyncAlert = true
                        }
                        
                        if let lastSync = UserDefaults.standard.object(forKey: "lastContactSync") as? Date {
                            HStack {
                                Text("Last Sync:")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(lastSync, style: .relative)
                                    .foregroundColor(.secondary)
                            }
                            .font(.caption)
                        }
                    }
                }
                
                Section("Privacy & Security") {
                    Toggle("Encrypt Sensitive Data", isOn: $encryptSensitiveData)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Default Privacy Level")
                            .font(.headline)
                        
                        Picker("Privacy Level", selection: .constant(ContactPrivacyLevel.normal)) {
                            ForEach(ContactPrivacyLevel.allCases, id: \.self) { level in
                                VStack(alignment: .leading) {
                                    Text(level.displayName)
                                    Text(level.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .tag(level)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                
                Section("Import & Export") {
                    Toggle("Allow Contact Import", isOn: $allowContactImport)
                    
                    Button("Import from Device Contacts") {
                        // TODO: Implement device contact import
                    }
                    .disabled(!allowContactImport)
                    
                    Button("Export Contacts") {
                        // TODO: Implement contact export
                    }
                }
                
                Section("Statistics") {
                    HStack {
                        Text("Total Contacts")
                        Spacer()
                        Text("\(contactManager.contacts.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Favorites")
                        Spacer()
                        Text("\(contactManager.contacts.filter { $0.isFavorite }.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Blocked")
                        Spacer()
                        Text("\(contactManager.contacts.filter { $0.isBlocked }.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Groups")
                        Spacer()
                        Text("\(contactManager.contactGroups.count)")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Advanced") {
                    Button("Clear All Local Data") {
                        // TODO: Implement data clearing
                    }
                    .foregroundColor(.red)
                    
                    Button("Reset Contact Permissions") {
                        // TODO: Implement permission reset
                    }
                }
            }
            .navigationTitle("Contact Settings")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Sync Contacts", isPresented: $showingSyncAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sync") {
                    performSync()
                }
            } message: {
                switch syncAction {
                case .toCloud:
                    Text("This will upload all local contacts to the cloud. Existing cloud contacts may be overwritten.")
                case .fromCloud:
                    Text("This will download all cloud contacts. Local contacts may be overwritten.")
                }
            }
        }
    }
    
    private func performSync() {
        Task {
            switch syncAction {
            case .toCloud:
                await contactManager.syncAllContactsToCloud()
            case .fromCloud:
                await contactManager.syncAllContactsFromCloud()
            }
            
            UserDefaults.standard.set(Date(), forKey: "lastContactSync")
        }
    }
}

// MARK: - Privacy Settings View
struct ContactPrivacySettingsView: View {
    @State private var defaultPrivacyLevel = ContactPrivacyLevel.normal
    @State private var encryptEmails = true
    @State private var encryptPhoneNumbers = true
    @State private var encryptNotes = true
    @State private var requireBiometricAccess = false
    @State private var autoBlockUnknown = false
    @State private var allowAnalytics = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Default Privacy") {
                    Picker("Default Privacy Level", selection: $defaultPrivacyLevel) {
                        ForEach(ContactPrivacyLevel.allCases, id: \.self) { level in
                            VStack(alignment: .leading) {
                                Text(level.displayName)
                                Text(level.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .tag(level)
                        }
                    }
                    .pickerStyle(.wheel)
                }
                
                Section("Data Encryption") {
                    Toggle("Encrypt Email Addresses", isOn: $encryptEmails)
                    Toggle("Encrypt Phone Numbers", isOn: $encryptPhoneNumbers)
                    Toggle("Encrypt Notes", isOn: $encryptNotes)
                }
                
                Section("Access Control") {
                    Toggle("Require Biometric Access", isOn: $requireBiometricAccess)
                    Toggle("Auto-block Unknown Contacts", isOn: $autoBlockUnknown)
                }
                
                Section("Analytics") {
                    Toggle("Allow Contact Analytics", isOn: $allowAnalytics)
                    
                    Text("Help improve the app by sharing anonymous usage data about contact management features.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section("Privacy Information") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How we protect your data:")
                            .font(.headline)
                        
                        Text("• All contact data is stored locally on your device")
                        Text("• Cloud sync uses end-to-end encryption")
                        Text("• Sensitive fields can be additionally encrypted")
                        Text("• No contact data is shared with third parties")
                        Text("• You have full control over what data is synced")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Privacy Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Preview
struct ContactSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ContactSettingsView(contactManager: ContactManager())
    }
}