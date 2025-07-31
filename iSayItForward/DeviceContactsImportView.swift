import Foundation
import Contacts
import SwiftUI

// MARK: - Device Contacts Import Service
class DeviceContactsImportService: ObservableObject {
    @Published var isImporting = false
    @Published var importProgress: Double = 0.0
    @Published var importError: ContactImportError?
    @Published var importResults: ImportResults?
    
    private let contactStore = CNContactStore()
    private let contactManager: ContactManager
    
    init(contactManager: ContactManager) {
        self.contactManager = contactManager
    }
    
    // MARK: - Permission Management
    
    func requestContactsPermission() async -> Bool {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        
        switch status {
        case .authorized:
            return true
        case .notDetermined:
            do {
                return try await contactStore.requestAccess(for: .contacts)
            } catch {
                DispatchQueue.main.async {
                    self.importError = .permissionDenied
                }
                return false
            }
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.importError = .permissionDenied
            }
            return false
        @unknown default:
            return false
        }
    }
    
    // MARK: - Import Functionality
    
    func importAllContacts() async {
        guard await requestContactsPermission() else { return }
        
        DispatchQueue.main.async {
            self.isImporting = true
            self.importProgress = 0.0
            self.importError = nil
            self.importResults = nil
        }
        
        do {
            let deviceContacts = try await fetchDeviceContacts()
            await processImportedContacts(deviceContacts)
        } catch {
            DispatchQueue.main.async {
                self.importError = .fetchFailed(error.localizedDescription)
                self.isImporting = false
            }
        }
    }
    
    func importSelectedContacts(_ selectedContacts: [CNContact]) async {
        DispatchQueue.main.async {
            self.isImporting = true
            self.importProgress = 0.0
            self.importError = nil
        }
        
        await processImportedContacts(selectedContacts)
    }
    
    private func fetchDeviceContacts() async throws -> [CNContact] {
        return try await withCheckedThrowingContinuation { continuation in
            let keys = [
                CNContactGivenNameKey,
                CNContactFamilyNameKey,
                CNContactEmailAddressesKey,
                CNContactPhoneNumbersKey,
                CNContactImageDataKey,
                CNContactNoteKey,
                CNContactOrganizationNameKey
            ] as [CNKeyDescriptor]
            
            let request = CNContactFetchRequest(keysToFetch: keys)
            var contacts: [CNContact] = []
            
            do {
                try contactStore.enumerateContacts(with: request) { contact, _ in
                    contacts.append(contact)
                    return true
                }
                continuation.resume(returning: contacts)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func processImportedContacts(_ deviceContacts: [CNContact]) async {
        let totalContacts = Double(deviceContacts.count)
        var importedCount = 0
        var skippedCount = 0
        var errorCount = 0
        
        for (index, deviceContact) in deviceContacts.enumerated() {
            // Update progress
            DispatchQueue.main.async {
                self.importProgress = Double(index) / totalContacts
            }
            
            // Convert device contact to app contact
            do {
                if let appContact = try convertDeviceContactToAppContact(deviceContact) {
                    // Check if contact already exists
                    if !contactAlreadyExists(appContact) {
                        contactManager.addContact(appContact)
                        importedCount += 1
                    } else {
                        skippedCount += 1
                    }
                } else {
                    skippedCount += 1
                }
            } catch {
                errorCount += 1
                print("Error converting contact \(deviceContact.givenName) \(deviceContact.familyName): \(error)")
            }
            
            // Small delay to prevent UI blocking
            try? await Task.sleep(nanoseconds: 1_000_000) // 1ms
        }
        
        DispatchQueue.main.async {
            self.importProgress = 1.0
            self.isImporting = false
            self.importResults = ImportResults(
                imported: importedCount,
                skipped: skippedCount,
                errors: errorCount,
                total: deviceContacts.count
            )
        }
    }
    
    private func convertDeviceContactToAppContact(_ deviceContact: CNContact) throws -> Contact? {
        let firstName = deviceContact.givenName
        let lastName = deviceContact.familyName
        
        // Skip contacts without names and contact info
        guard !firstName.isEmpty || !lastName.isEmpty ||
              !deviceContact.emailAddresses.isEmpty ||
              !deviceContact.phoneNumbers.isEmpty else {
            return nil
        }
        
        // Extract email (use first email if multiple)
        let email = deviceContact.emailAddresses.first?.value as String?
        
        // Extract phone (use first phone if multiple)
        let phoneNumber = deviceContact.phoneNumbers.first?.value.stringValue
        
        // Create contact
        var contact = Contact(
            firstName: firstName,
            lastName: lastName,
            email: email,
            phoneNumber: phoneNumber
        )
        
        // Add notes if available
        if !deviceContact.note.isEmpty {
            contact.notes = deviceContact.note
        }
        
        // Add avatar image if available
        if let imageData = deviceContact.imageData {
            contact.avatarImageData = imageData
        }
        
        // Add organization as a tag if available
        if !deviceContact.organizationName.isEmpty {
            contact.tags.append(deviceContact.organizationName)
        }
        
        return contact
    }
    
    private func contactAlreadyExists(_ newContact: Contact) -> Bool {
        return contactManager.contacts.contains { existingContact in
            // Check for exact email match
            if let newEmail = newContact.email,
               let existingEmail = existingContact.email,
               !newEmail.isEmpty && !existingEmail.isEmpty {
                return newEmail.lowercased() == existingEmail.lowercased()
            }
            
            // Check for exact phone match
            if let newPhone = newContact.phoneNumber,
               let existingPhone = existingContact.phoneNumber,
               !newPhone.isEmpty && !existingPhone.isEmpty {
                let cleanNewPhone = newPhone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                let cleanExistingPhone = existingPhone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                return cleanNewPhone == cleanExistingPhone
            }
            
            // Check for name similarity (if no email/phone)
            if newContact.email == nil && newContact.phoneNumber == nil {
                return existingContact.firstName.lowercased() == newContact.firstName.lowercased() &&
                       existingContact.lastName.lowercased() == newContact.lastName.lowercased()
            }
            
            return false
        }
    }
    
    // MARK: - Device Contacts Fetching for Selection
    
    func fetchDeviceContactsForSelection() async throws -> [CNContact] {
        guard await requestContactsPermission() else {
            throw ContactImportError.permissionDenied
        }
        
        return try await fetchDeviceContacts()
    }
}

// MARK: - Import Results
struct ImportResults {
    let imported: Int
    let skipped: Int
    let errors: Int
    let total: Int
    
    var successRate: Double {
        guard total > 0 else { return 0 }
        return Double(imported) / Double(total)
    }
}

// MARK: - Import Errors
enum ContactImportError: LocalizedError {
    case permissionDenied
    case fetchFailed(String)
    case conversionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Permission to access contacts was denied. Please enable contacts access in Settings."
        case .fetchFailed(let message):
            return "Failed to fetch device contacts: \(message)"
        case .conversionFailed(let message):
            return "Failed to convert contact: \(message)"
        }
    }
}

// MARK: - Device Contacts Import View
struct DeviceContactsImportView: View {
    @ObservedObject var contactManager: ContactManager
    @StateObject private var importService: DeviceContactsImportService
    @Environment(\.presentationMode) var presentationMode
    
    @State private var importMode: ImportMode = .all
    @State private var deviceContacts: [CNContact] = []
    @State private var selectedContacts: Set<String> = []
    @State private var showingPermissionAlert = false
    @State private var isLoadingDeviceContacts = false
    
    enum ImportMode: String, CaseIterable {
        case all = "Import All"
        case selective = "Select Contacts"
    }
    
    init(contactManager: ContactManager) {
        self.contactManager = contactManager
        self._importService = StateObject(wrappedValue: DeviceContactsImportService(contactManager: contactManager))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if importService.isImporting {
                    importProgressView
                } else if let results = importService.importResults {
                    importResultsView(results)
                } else {
                    importOptionsView
                }
            }
            .navigationTitle("Import Contacts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                if importService.importResults != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            }
            .alert("Contacts Permission Required", isPresented: $showingPermissionAlert) {
                Button("Settings") {
                    openAppSettings()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This app needs access to your contacts to import them. Please enable contacts access in Settings.")
            }
            .alert("Import Error", isPresented: .constant(importService.importError != nil)) {
                Button("OK") {
                    importService.importError = nil
                }
            } message: {
                Text(importService.importError?.localizedDescription ?? "")
            }
        }
    }
    
    private var importOptionsView: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Import Device Contacts")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Import contacts from your device's contact list to quickly populate your iSIF contacts.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                VStack(spacing: 16) {
                    Picker("Import Mode", selection: $importMode) {
                        ForEach(ImportMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    if importMode == .selective {
                        selectiveImportSection
                    } else {
                        allImportSection
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                
                importWarningSection
            }
        }
    }
    
    private var allImportSection: some View {
        VStack(spacing: 12) {
            Text("Import All Contacts")
                .font(.headline)
            
            Text("This will import all contacts from your device. Duplicates will be automatically skipped.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Start Import") {
                startAllImport()
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private var selectiveImportSection: some View {
        VStack(spacing: 12) {
            Text("Select Contacts to Import")
                .font(.headline)
            
            if isLoadingDeviceContacts {
                ProgressView("Loading device contacts...")
                    .padding()
            } else if deviceContacts.isEmpty {
                Button("Load Device Contacts") {
                    loadDeviceContacts()
                }
                .buttonStyle(.bordered)
            } else {
                deviceContactsList
                
                Button("Import Selected (\(selectedContacts.count))") {
                    startSelectiveImport()
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedContacts.isEmpty)
            }
        }
    }
    
    private var deviceContactsList: some View {
        List {
            ForEach(deviceContacts, id: \.identifier) { contact in
                DeviceContactRowView(
                    contact: contact,
                    isSelected: selectedContacts.contains(contact.identifier)
                ) {
                    toggleContactSelection(contact)
                }
            }
        }
        .frame(maxHeight: 300)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var importWarningSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(.orange)
                Text("Important Information")
                    .font(.headline)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("• Contacts with matching email or phone numbers will be skipped")
                Text("• Contact photos and notes will be imported if available")
                Text("• Organization names will be added as tags")
                Text("• You can review and edit imported contacts afterwards")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemYellow).opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
    
    private var importProgressView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Importing Contacts...")
                .font(.headline)
            
            ProgressView(value: importService.importProgress)
                .frame(maxWidth: 200)
            
            Text("\(Int(importService.importProgress * 100))% Complete")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    private func importResultsView(_ results: ImportResults) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Import Complete")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                ImportStatRow(title: "Imported", value: results.imported, color: .green)
                ImportStatRow(title: "Skipped", value: results.skipped, color: .orange)
                ImportStatRow(title: "Errors", value: results.errors, color: .red)
                ImportStatRow(title: "Total", value: results.total, color: .primary)
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            if results.successRate < 1.0 {
                Text("Some contacts were skipped or had errors. This is normal for duplicate contacts or contacts with incomplete information.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding()
    }
    
    private func loadDeviceContacts() {
        isLoadingDeviceContacts = true
        Task {
            do {
                let contacts = try await importService.fetchDeviceContactsForSelection()
                DispatchQueue.main.async {
                    self.deviceContacts = contacts.sorted { 
                        $0.givenName + $0.familyName < $1.givenName + $1.familyName 
                    }
                    self.isLoadingDeviceContacts = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoadingDeviceContacts = false
                    if case ContactImportError.permissionDenied = error {
                        self.showingPermissionAlert = true
                    }
                }
            }
        }
    }
    
    private func startAllImport() {
        Task {
            await importService.importAllContacts()
        }
    }
    
    private func startSelectiveImport() {
        let contactsToImport = deviceContacts.filter { selectedContacts.contains($0.identifier) }
        Task {
            await importService.importSelectedContacts(contactsToImport)
        }
    }
    
    private func toggleContactSelection(_ contact: CNContact) {
        if selectedContacts.contains(contact.identifier) {
            selectedContacts.remove(contact.identifier)
        } else {
            selectedContacts.insert(contact.identifier)
        }
    }
    
    private func openAppSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
}

// MARK: - Device Contact Row View
struct DeviceContactRowView: View {
    let contact: CNContact
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            if let imageData = contact.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(initials(for: contact))
                            .font(.caption)
                            .fontWeight(.medium)
                    )
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces))
                    .font(.body)
                
                if let email = contact.emailAddresses.first?.value as String? {
                    Text(email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if let phone = contact.phoneNumbers.first?.value.stringValue {
                    Text(phone)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .blue : .secondary)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
    
    private func initials(for contact: CNContact) -> String {
        let first = contact.givenName.first?.uppercased() ?? ""
        let last = contact.familyName.first?.uppercased() ?? ""
        return first + last
    }
}

// MARK: - Import Stat Row
struct ImportStatRow: View {
    let title: String
    let value: Int
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.body)
            Spacer()
            Text("\(value)")
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

// MARK: - Preview
struct DeviceContactsImportView_Previews: PreviewProvider {
    static var previews: some View {
        DeviceContactsImportView(contactManager: ContactManager())
    }
}