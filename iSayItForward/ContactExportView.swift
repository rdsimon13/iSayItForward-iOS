import SwiftUI
import MessageUI

// MARK: - Contact Export View
struct ContactExportView: View {
    @ObservedObject var contactManager: ContactManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var exportFormat: ExportFormat = .csv
    @State private var selectedContacts: Set<UUID> = []
    @State private var exportMode: ExportMode = .all
    @State private var includeImages = false
    @State private var includePrivateContacts = false
    @State private var isExporting = false
    @State private var exportedData: Data?
    @State private var showingShareSheet = false
    @State private var showingMailComposer = false
    @State private var exportError: ExportError?
    
    enum ExportFormat: String, CaseIterable {
        case csv = "CSV"
        case json = "JSON"
        case vcard = "vCard"
        
        var fileExtension: String {
            switch self {
            case .csv: return "csv"
            case .json: return "json"
            case .vcard: return "vcf"
            }
        }
        
        var mimeType: String {
            switch self {
            case .csv: return "text/csv"
            case .json: return "application/json"
            case .vcard: return "text/x-vcard"
            }
        }
    }
    
    enum ExportMode: String, CaseIterable {
        case all = "All Contacts"
        case favorites = "Favorites Only"
        case selected = "Selected Contacts"
        case groups = "By Groups"
    }
    
    private var filteredContacts: [Contact] {
        var contacts = contactManager.contacts
        
        if !includePrivateContacts {
            contacts = contacts.filter { $0.privacyLevel != .private_ }
        }
        
        switch exportMode {
        case .all:
            return contacts
        case .favorites:
            return contacts.filter { $0.isFavorite }
        case .selected:
            return contacts.filter { selectedContacts.contains($0.id) }
        case .groups:
            return contacts // TODO: Implement group-based filtering
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Export Options") {
                    Picker("Format", selection: $exportFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Text(format.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    Picker("Contacts to Export", selection: $exportMode) {
                        ForEach(ExportMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue)
                        }
                    }
                    
                    if exportMode == .selected {
                        contactSelectionSection
                    }
                }
                
                Section("Include Additional Data") {
                    Toggle("Include Contact Images", isOn: $includeImages)
                    Toggle("Include Private Contacts", isOn: $includePrivateContacts)
                }
                
                Section("Export Summary") {
                    HStack {
                        Text("Contacts to Export")
                        Spacer()
                        Text("\(filteredContacts.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Estimated File Size")
                        Spacer()
                        Text(estimatedFileSize)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Export Actions") {
                    Button("Export & Share") {
                        performExport()
                    }
                    .disabled(isExporting || filteredContacts.isEmpty)
                    
                    if isExporting {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Exporting...")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("Export Information") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Export includes:")
                            .font(.headline)
                        
                        Text("• Contact names, emails, and phone numbers")
                        Text("• Notes and tags")
                        Text("• Privacy levels and favorite status")
                        if includeImages {
                            Text("• Contact photos (if available)")
                        }
                        
                        Text("\nPrivacy Note: Exported data is not encrypted. Handle with care.")
                            .fontWeight(.semibold)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Export Contacts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let data = exportedData {
                    ShareSheet(items: [createTempFile(data: data)])
                }
            }
            .sheet(isPresented: $showingMailComposer) {
                if let data = exportedData {
                    MailComposerView(
                        data: data,
                        fileName: exportFileName,
                        mimeType: exportFormat.mimeType
                    )
                }
            }
            .alert("Export Error", isPresented: .constant(exportError != nil)) {
                Button("OK") {
                    exportError = nil
                }
            } message: {
                Text(exportError?.localizedDescription ?? "")
            }
        }
    }
    
    private var contactSelectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select Contacts to Export")
                .font(.headline)
            
            ForEach(contactManager.contacts) { contact in
                HStack {
                    ContactAvatarView(contact: contact, size: 30)
                    
                    VStack(alignment: .leading) {
                        Text(contact.displayName)
                            .font(.body)
                        if let email = contact.email {
                            Text(email)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        toggleContactSelection(contact)
                    }) {
                        Image(systemName: selectedContacts.contains(contact.id) ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(selectedContacts.contains(contact.id) ? .blue : .secondary)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
    
    private var estimatedFileSize: String {
        let baseSize = filteredContacts.count * 200 // ~200 bytes per contact
        let imageSize = includeImages ? filteredContacts.count * 50000 : 0 // ~50KB per image
        let totalBytes = baseSize + imageSize
        
        if totalBytes < 1024 {
            return "\(totalBytes) B"
        } else if totalBytes < 1024 * 1024 {
            return "\(totalBytes / 1024) KB"
        } else {
            return String(format: "%.1f MB", Double(totalBytes) / (1024 * 1024))
        }
    }
    
    private var exportFileName: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        return "iSIF_Contacts_\(dateString).\(exportFormat.fileExtension)"
    }
    
    private func toggleContactSelection(_ contact: Contact) {
        if selectedContacts.contains(contact.id) {
            selectedContacts.remove(contact.id)
        } else {
            selectedContacts.insert(contact.id)
        }
    }
    
    private func performExport() {
        isExporting = true
        
        Task {
            do {
                let data = try await exportContacts(filteredContacts, format: exportFormat)
                
                DispatchQueue.main.async {
                    self.exportedData = data
                    self.isExporting = false
                    
                    if MFMailComposeViewController.canSendMail() {
                        self.showingMailComposer = true
                    } else {
                        self.showingShareSheet = true
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.exportError = .exportFailed(error.localizedDescription)
                    self.isExporting = false
                }
            }
        }
    }
    
    private func exportContacts(_ contacts: [Contact], format: ExportFormat) async throws -> Data {
        switch format {
        case .csv:
            return try exportToCSV(contacts)
        case .json:
            return try exportToJSON(contacts)
        case .vcard:
            return try exportToVCard(contacts)
        }
    }
    
    private func exportToCSV(_ contacts: [Contact]) throws -> Data {
        var csvContent = "First Name,Last Name,Email,Phone,Notes,Tags,Is Favorite,Is Blocked,Privacy Level,Created Date\n"
        
        for contact in contacts {
            let row = [
                contact.firstName.replacingOccurrences(of: ",", with: ";"),
                contact.lastName.replacingOccurrences(of: ",", with: ";"),
                contact.email ?? "",
                contact.phoneNumber ?? "",
                (contact.notes ?? "").replacingOccurrences(of: ",", with: ";"),
                contact.tags.joined(separator: "|"),
                contact.isFavorite ? "Yes" : "No",
                contact.isBlocked ? "Yes" : "No",
                contact.privacyLevel.displayName,
                ISO8601DateFormatter().string(from: contact.createdDate)
            ].joined(separator: ",")
            
            csvContent += row + "\n"
        }
        
        guard let data = csvContent.data(using: .utf8) else {
            throw ExportError.encodingFailed
        }
        
        return data
    }
    
    private func exportToJSON(_ contacts: [Contact]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        let exportData = ContactExportData(
            exportDate: Date(),
            contactCount: contacts.count,
            contacts: contacts
        )
        
        return try encoder.encode(exportData)
    }
    
    private func exportToVCard(_ contacts: [Contact]) throws -> Data {
        var vCardContent = ""
        
        for contact in contacts {
            vCardContent += "BEGIN:VCARD\n"
            vCardContent += "VERSION:3.0\n"
            vCardContent += "FN:\(contact.fullName)\n"
            vCardContent += "N:\(contact.lastName);\(contact.firstName);;;\n"
            
            if let email = contact.email {
                vCardContent += "EMAIL:\(email)\n"
            }
            
            if let phone = contact.phoneNumber {
                vCardContent += "TEL:\(phone)\n"
            }
            
            if let notes = contact.notes {
                vCardContent += "NOTE:\(notes)\n"
            }
            
            vCardContent += "END:VCARD\n"
        }
        
        guard let data = vCardContent.data(using: .utf8) else {
            throw ExportError.encodingFailed
        }
        
        return data
    }
    
    private func createTempFile(data: Data) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(exportFileName)
        
        try? data.write(to: fileURL)
        return fileURL
    }
}

// MARK: - Export Data Structure
struct ContactExportData: Codable {
    let exportDate: Date
    let contactCount: Int
    let contacts: [Contact]
}

// MARK: - Export Errors
enum ExportError: LocalizedError {
    case noContactsSelected
    case encodingFailed
    case exportFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .noContactsSelected:
            return "No contacts selected for export"
        case .encodingFailed:
            return "Failed to encode contact data"
        case .exportFailed(let message):
            return "Export failed: \(message)"
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Mail Composer
struct MailComposerView: UIViewControllerRepresentable {
    let data: Data
    let fileName: String
    let mimeType: String
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.setSubject("iSIF Contact Export")
        composer.setMessageBody("Please find attached your exported contacts from iSIF.", isHTML: false)
        composer.addAttachmentData(data, mimeType: mimeType, fileName: fileName)
        composer.mailComposeDelegate = context.coordinator
        return composer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            controller.dismiss(animated: true)
        }
    }
}

// MARK: - Preview
struct ContactExportView_Previews: PreviewProvider {
    static var previews: some View {
        ContactExportView(contactManager: ContactManager())
    }
}