import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// This defines the different recipient modes.
// It must be defined outside the main View struct.
enum RecipientMode: String, CaseIterable {
    case single = "Single"
    case multiple = "Multiple"
    case group = "Group"
}

struct CreateSIFView: View {
    // MARK: - State Variables
    
    // Form fields
    @State private var recipientMode: RecipientMode = .single
    @State private var singleRecipient: String = ""
    @State private var multipleRecipients: String = ""
    @State private var selectedGroup: String = "Team" // Default value

    @State private var subject: String = ""
    @State private var message: String = ""

    // Content and attachments
    @State private var selectedContentType: ContentType = .text
    @State private var contentAttachments: [ContentAttachment] = []
    @State private var selectedTemplate: TemplateItem? = nil
    @State private var showingContentPicker = false
    @State private var showingTemplatePicker = false
    @State private var dragOver = false

    // Scheduling
    @State private var shouldSchedule = false
    @State private var scheduleDate = Date()

    // Feedback for the user
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    // Placeholder data for the group picker
    let groups = ["Team", "Family", "Friends"]

    var body: some View {
        // Use a NavigationStack to provide a title bar
        NavigationStack {
            ZStack {
                Color.mainAppGradient.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        
                        Picker("Recipient Mode", selection: $recipientMode) {
                            ForEach(RecipientMode.allCases, id: \.self) {
                                Text($0.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                        .background(.white.opacity(0.3))
                        .cornerRadius(8)

                        // Input fields for recipients, subject, and message
                        switch recipientMode {
                        case .single:
                            TextField("Recipient's Email", text: $singleRecipient)
                                .textFieldStyle(PillTextFieldStyle())
                        case .multiple:
                            TextField("Recipients (comma separated)", text: $multipleRecipients)
                                .textFieldStyle(PillTextFieldStyle())
                        case .group:
                            Picker("Select Group", selection: $selectedGroup) {
                                ForEach(groups, id: \.self) { Text($0) }
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .background(.white.opacity(0.8))
                            .clipShape(Capsule())
                        }

                        TextField("Subject", text: $subject)
                            .textFieldStyle(PillTextFieldStyle())

                        TextEditor(text: $message)
                            .frame(height: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .padding(8)
                            .background(.white.opacity(0.8))
                            .cornerRadius(20)

                        // Content Type Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Content Type")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Picker("Content Type", selection: $selectedContentType) {
                                ForEach(ContentType.allCases, id: \.self) { type in
                                    Text(type.displayName).tag(type)
                                }
                            }
                            .pickerStyle(.segmented)
                            .background(.white.opacity(0.3))
                            .cornerRadius(8)
                        }

                        // Template Selection
                        if selectedTemplate == nil {
                            Button("Select Template") {
                                showingTemplatePicker = true
                            }
                            .buttonStyle(SecondaryActionButtonStyle())
                        } else {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Template: \(selectedTemplate?.name ?? "")")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                    Text(selectedTemplate?.category.rawValue ?? "")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                Spacer()
                                Button("Change") {
                                    showingTemplatePicker = true
                                }
                                .font(.caption)
                                .foregroundColor(.brandYellow)
                                Button("Remove") {
                                    selectedTemplate = nil
                                }
                                .font(.caption)
                                .foregroundColor(.red)
                            }
                            .padding()
                            .background(.white.opacity(0.2))
                            .cornerRadius(12)
                        }

                        // Attachment Section
                        contentAttachmentSection

                        // Scheduling UI
                        Toggle("Schedule for later", isOn: $shouldSchedule)
                            .tint(Color.brandYellow)
                            .padding()
                            .background(.white.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 16))

                        if shouldSchedule {
                            DatePicker("Pick Date & Time", selection: $scheduleDate)
                                .datePickerStyle(.graphical)
                                .padding()
                                .background(.white.opacity(0.85))
                                .cornerRadius(16)
                        }
                        
                        Spacer()

                        // Send Button
                        Button("Send SIF") {
                            saveSIF()
                        }
                        .buttonStyle(PrimaryActionButtonStyle())
                        .padding(.top)
                    }
                    .padding()
                }
                .navigationTitle("Create a SIF")
                .navigationBarTitleDisplayMode(.inline) // Smaller title style
            }
            .alert(isPresented: $showingAlert) {
                Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .sheet(isPresented: $showingContentPicker) {
                ContentPickerView(
                    selectedContentType: $selectedContentType,
                    contentAttachments: $contentAttachments
                )
            }
            .sheet(isPresented: $showingTemplatePicker) {
                TemplatePickerView(selectedTemplate: $selectedTemplate)
            }
        }
    }

    // MARK: - Content Attachment Section
    private var contentAttachmentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Attachments")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Button("Add Content") {
                    showingContentPicker = true
                }
                .font(.caption)
                .foregroundColor(.brandYellow)
            }
            
            if contentAttachments.isEmpty {
                // Drag and drop area
                RoundedRectangle(cornerRadius: 12)
                    .fill(dragOver ? Color.brandYellow.opacity(0.3) : Color.white.opacity(0.2))
                    .frame(height: 80)
                    .overlay(
                        VStack {
                            Image(systemName: "plus.circle")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.7))
                            Text("Drag files here or tap 'Add Content'")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    )
                    .onDrop(of: ["public.file-url"], isTargeted: $dragOver) { providers in
                        handleDroppedFiles(providers)
                    }
            } else {
                // Show attachments
                ForEach(contentAttachments) { attachment in
                    contentAttachmentRow(attachment)
                }
            }
        }
    }
    
    // MARK: - Content Attachment Row
    private func contentAttachmentRow(_ attachment: ContentAttachment) -> some View {
        HStack {
            Image(systemName: iconForContentType(attachment.contentType))
                .foregroundColor(.brandYellow)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(attachment.fileName)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack {
                    Text(attachment.contentType.displayName)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(ByteFormatter.format(bytes: attachment.fileSize))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            Spacer()
            
            Button("Remove") {
                removeAttachment(attachment)
            }
            .font(.caption)
            .foregroundColor(.red)
        }
        .padding()
        .background(.white.opacity(0.2))
        .cornerRadius(8)
    }
    
    // MARK: - Helper Methods
    private func iconForContentType(_ type: ContentType) -> String {
        switch type {
        case .text: return "doc.plaintext"
        case .audio: return "mic.circle"
        case .photo: return "photo"
        case .video: return "video"
        case .document: return "doc.text"
        }
    }
    
    private func handleDroppedFiles(_ providers: [NSItemProvider]) -> Bool {
        // Simplified implementation - in real app would handle file URLs
        // For now, just show success message
        showAlert(title: "Files Dropped", message: "Drag and drop functionality will be implemented with file handling.")
        return true
    }
    
    private func removeAttachment(_ attachment: ContentAttachment) {
        contentAttachments.removeAll { $0.id == attachment.id }
    }
    
    private func addSampleAttachment() {
        let sampleAttachment = ContentAttachment(
            contentType: selectedContentType,
            fileName: "sample.\(selectedContentType.allowedExtensions.first ?? "txt")",
            fileSize: 1024,
            metadata: ["source": "manual_add"]
        )
        contentAttachments.append(sampleAttachment)
    }

    // MARK: - Firestore Logic
    func saveSIF() {
        guard let authorUid = Auth.auth().currentUser?.uid else {
            showAlert(title: "Error", message: "You must be logged in to send a SIF.")
            return
        }

        var recipientList: [String]
        switch recipientMode {
        case .single:
            guard !singleRecipient.isEmpty else {
                showAlert(title: "Missing Information", message: "Please enter a recipient.")
                return
            }
            recipientList = [singleRecipient]
        case .multiple:
            guard !multipleRecipients.isEmpty else {
                showAlert(title: "Missing Information", message: "Please enter recipients.")
                return
            }
            recipientList = multipleRecipients.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
        case .group:
            recipientList = [selectedGroup]
        }

        // Validate attachments
        let invalidAttachments = contentAttachments.filter { !$0.isValidSize || !$0.isValidExtension }
        if !invalidAttachments.isEmpty {
            showAlert(title: "Invalid Attachments", message: "Some attachments are invalid. Please check file sizes and types.")
            return
        }

        // Create content metadata
        var metadata: [String: String] = [:]
        if let template = selectedTemplate {
            metadata["template_name"] = template.name
            metadata["template_category"] = template.category.rawValue
        }
        metadata["content_type"] = selectedContentType.rawValue
        metadata["attachment_count"] = "\(contentAttachments.count)"

        let newSif = SIFItem(
            authorUid: authorUid,
            recipients: recipientList,
            subject: subject,
            message: message,
            createdDate: Date(),
            scheduledDate: shouldSchedule ? scheduleDate : Date(),
            contentAttachments: contentAttachments,
            templateName: selectedTemplate?.name,
            templateCategory: selectedTemplate?.category.rawValue,
            contentMetadata: metadata
        )

        let db = Firestore.firestore()
        do {
            // The 'from' parameter requires SIFItem to conform to Codable
            try db.collection("sifs").addDocument(from: newSif)
            showAlert(title: "Success!", message: "Your SIF has been saved and is scheduled for delivery.")
            // Clear form fields
            clearForm()
        } catch let error {
            showAlert(title: "Error", message: "There was an issue saving your SIF: \(error.localizedDescription)")
        }
    }
    
    // Helper function to clear form
    func clearForm() {
        singleRecipient = ""
        multipleRecipients = ""
        subject = ""
        message = ""
        contentAttachments = []
        selectedTemplate = nil
        shouldSchedule = false
        scheduleDate = Date()
    }
    
    // Helper function to show alerts
    func showAlert(title: String, message: String) {
        self.alertTitle = title
        self.alertMessage = message
        self.showingAlert = true
    }
}

struct CreateSIFView_Previews: PreviewProvider {
    static var previews: some View {
        CreateSIFView()
    }
}
