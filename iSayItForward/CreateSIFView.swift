import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import PhotosUI
import UniformTypeIdentifiers

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

    // Scheduling and Control
    @State private var shouldSchedule = false
    @State private var scheduleDate = Date()
    @State private var shouldSetExpiration = false
    @State private var expirationDate = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
    @State private var notifyOnDelivery = true
    @State private var notifyOnOpen = false

    // File Attachments
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var selectedFiles: [URL] = []
    @State private var uploadedFiles: [UploadedFile] = []
    @State private var isUploading = false
    @State private var uploadProgress: Double = 0.0
    @State private var showingFileImporter = false

    // Feedback for the user
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    // Services
    @StateObject private var deliveryService = SIFDeliveryService.shared
    @StateObject private var contentService = ContentManagementService.shared

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

                        // File Attachments Section
                        AttachmentsSection(
                            selectedPhotos: $selectedPhotos,
                            selectedFiles: $selectedFiles,
                            uploadedFiles: $uploadedFiles,
                            isUploading: $isUploading,
                            uploadProgress: $uploadProgress,
                            showingFileImporter: $showingFileImporter
                        )

                        // Scheduling UI
                        VStack(spacing: 12) {
                            Toggle("Schedule for later", isOn: $shouldSchedule)
                                .tint(Color.brandYellow)
                                .padding()
                                .background(.white.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 16))

                            if shouldSchedule {
                                DatePicker("Pick Date & Time", selection: $scheduleDate, in: Date()...)
                                    .datePickerStyle(.graphical)
                                    .padding()
                                    .background(.white.opacity(0.85))
                                    .cornerRadius(16)
                            }
                            
                            // Expiration Settings
                            Toggle("Set expiration date", isOn: $shouldSetExpiration)
                                .tint(Color.brandYellow)
                                .padding()
                                .background(.white.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                
                            if shouldSetExpiration {
                                DatePicker("Expiration Date", selection: $expirationDate, in: Date()...)
                                    .datePickerStyle(.graphical)
                                    .padding()
                                    .background(.white.opacity(0.85))
                                    .cornerRadius(16)
                            }
                            
                            // Notification Settings
                            VStack(spacing: 8) {
                                Toggle("Notify when delivered", isOn: $notifyOnDelivery)
                                    .tint(Color.brandYellow)
                                    .padding()
                                    .background(.white.opacity(0.2))
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                
                                Toggle("Notify when opened", isOn: $notifyOnOpen)
                                    .tint(Color.brandYellow)
                                    .padding()
                                    .background(.white.opacity(0.2))
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                        }
                        
                        Spacer()

                        // Send Button
                        Button(shouldSchedule ? "Schedule SIF" : "Send SIF") {
                            Task {
                                await saveSIF()
                            }
                        }
                        .buttonStyle(PrimaryActionButtonStyle())
                        .disabled(isUploading)
                        .padding(.top)
                        
                        // Upload Progress
                        if isUploading {
                            ProgressView("Uploading attachments...", value: uploadProgress)
                                .progressViewStyle(LinearProgressViewStyle())
                                .padding(.top)
                        }
                    }
                    .padding()
                }
                .navigationTitle("Create a SIF")
                .navigationBarTitleDisplayMode(.inline) // Smaller title style
            }
            .alert(isPresented: $showingAlert) {
                Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .fileImporter(
                isPresented: $showingFileImporter,
                allowedContentTypes: [.item],
                allowsMultipleSelection: true
            ) { result in
                handleFileSelection(result)
            }
            .onChange(of: selectedPhotos) { _ in
                Task {
                    await processSelectedPhotos()
                }
            }
        }
    }

    // MARK: - Firestore Logic
    func saveSIF() async {
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

        guard !subject.isEmpty else {
            showAlert(title: "Missing Information", message: "Please enter a subject.")
            return
        }

        guard !message.isEmpty else {
            showAlert(title: "Missing Information", message: "Please enter a message.")
            return
        }

        // Upload files first if any are selected
        do {
            if !selectedFiles.isEmpty || !selectedPhotos.isEmpty {
                await uploadAttachments()
            }

            let newSif = SIFItem(
                authorUid: authorUid,
                recipients: recipientList,
                subject: subject,
                message: message,
                createdDate: Date(),
                scheduledDate: shouldSchedule ? scheduleDate : Date(),
                deliveryStatus: shouldSchedule ? .scheduled : .pending,
                attachmentURLs: uploadedFiles.map { $0.url },
                attachmentTypes: uploadedFiles.map { $0.type.rawValue },
                attachmentSizes: uploadedFiles.map { $0.size },
                totalAttachmentSize: uploadedFiles.reduce(0) { $0 + $1.size },
                expirationDate: shouldSetExpiration ? expirationDate : nil,
                notifyOnDelivery: notifyOnDelivery,
                notifyOnOpen: notifyOnOpen
            )

            let db = Firestore.firestore()
            let docRef = try await db.collection("sifs").addDocument(from: newSif)

            // Process delivery
            if shouldSchedule {
                var scheduledSIF = newSif
                scheduledSIF.id = docRef.documentID
                try await deliveryService.scheduleSIF(scheduledSIF)
                showAlert(title: "Success!", message: "Your SIF has been scheduled for delivery on \(scheduleDate.formatted(date: .abbreviated, time: .shortened)).")
            } else {
                var immediateSIF = newSif
                immediateSIF.id = docRef.documentID
                try await deliveryService.deliverSIF(immediateSIF)
                showAlert(title: "Success!", message: "Your SIF has been sent successfully!")
            }

            // Clear form
            clearForm()

        } catch let error {
            showAlert(title: "Error", message: "There was an issue saving your SIF: \(error.localizedDescription)")
        }
    }

    // MARK: - File Management
    
    func processSelectedPhotos() async {
        for photoItem in selectedPhotos {
            if let data = try? await photoItem.loadTransferable(type: Data.self) {
                // Save to temporary file
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).jpg")
                try? data.write(to: tempURL)
                selectedFiles.append(tempURL)
            }
        }
        selectedPhotos.removeAll()
    }

    func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            selectedFiles.append(contentsOf: urls)
        case .failure(let error):
            showAlert(title: "Error", message: "Failed to select files: \(error.localizedDescription)")
        }
    }

    func uploadAttachments() async {
        guard !selectedFiles.isEmpty else { return }
        
        isUploading = true
        uploadProgress = 0.0
        
        do {
            let tempSIFId = UUID().uuidString
            uploadedFiles = try await contentService.uploadFiles(selectedFiles, sifId: tempSIFId)
            
            // Clean up temporary files
            for fileURL in selectedFiles {
                try? FileManager.default.removeItem(at: fileURL)
            }
            
            selectedFiles.removeAll()
            
        } catch {
            showAlert(title: "Upload Error", message: "Failed to upload attachments: \(error.localizedDescription)")
        }
        
        isUploading = false
        uploadProgress = 0.0
    }

    func removeAttachment(_ file: UploadedFile) {
        uploadedFiles.removeAll { $0.id == file.id }
        Task {
            try? await contentService.deleteFile(file)
        }
    }

    func clearForm() {
        subject = ""
        message = ""
        singleRecipient = ""
        multipleRecipients = ""
        selectedGroup = "Team"
        shouldSchedule = false
        shouldSetExpiration = false
        scheduleDate = Date()
        expirationDate = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        notifyOnDelivery = true
        notifyOnOpen = false
        selectedFiles.removeAll()
        uploadedFiles.removeAll()
        recipientMode = .single
    }
    
    // Helper function to show alerts
    func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            self.alertTitle = title
            self.alertMessage = message
            self.showingAlert = true
        }
    }
}

// MARK: - Attachments Section

struct AttachmentsSection: View {
    @Binding var selectedPhotos: [PhotosPickerItem]
    @Binding var selectedFiles: [URL]
    @Binding var uploadedFiles: [UploadedFile]
    @Binding var isUploading: Bool
    @Binding var uploadProgress: Double
    @Binding var showingFileImporter: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Attachments")
                .font(.headline)
                .foregroundColor(.white)

            HStack(spacing: 12) {
                PhotosPicker(selection: $selectedPhotos, maxSelectionCount: 10, matching: .images) {
                    AttachmentButton(icon: "photo", label: "Photos")
                }

                Button {
                    showingFileImporter = true
                } label: {
                    AttachmentButton(icon: "doc", label: "Files")
                }
            }

            // Selected Files Preview
            if !selectedFiles.isEmpty || !uploadedFiles.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // Pending files
                        ForEach(Array(selectedFiles.enumerated()), id: \.offset) { index, fileURL in
                            PendingFileCard(fileURL: fileURL) {
                                selectedFiles.remove(at: index)
                            }
                        }

                        // Uploaded files
                        ForEach(uploadedFiles) { file in
                            UploadedFileCard(file: file) {
                                // Remove file action would go here
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding()
        .background(.white.opacity(0.1))
        .cornerRadius(16)
    }
}

struct AttachmentButton: View {
    let icon: String
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
            Text(label)
                .font(.caption)
        }
        .foregroundColor(.white)
        .padding()
        .background(.white.opacity(0.2))
        .cornerRadius(12)
    }
}

struct PendingFileCard: View {
    let fileURL: URL
    let onRemove: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc")
                .font(.title2)
                .foregroundColor(.orange)

            Text(fileURL.lastPathComponent)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            Button("Remove") {
                onRemove()
            }
            .font(.caption2)
            .foregroundColor(.red)
        }
        .padding(8)
        .frame(width: 100, height: 100)
        .background(.white.opacity(0.8))
        .cornerRadius(8)
    }
}

struct UploadedFileCard: View {
    let file: UploadedFile
    let onRemove: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: file.type.systemImageName)
                .font(.title2)
                .foregroundColor(.green)

            Text(file.name)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            Text(file.formattedSize)
                .font(.caption2)
                .foregroundColor(.secondary)

            Button("Remove") {
                onRemove()
            }
            .font(.caption2)
            .foregroundColor(.red)
        }
        .padding(8)
        .frame(width: 100, height: 100)
        .background(.white.opacity(0.8))
        .cornerRadius(8)
    }
}
}

struct CreateSIFView_Previews: PreviewProvider {
    static var previews: some View {
        CreateSIFView()
    }
}
