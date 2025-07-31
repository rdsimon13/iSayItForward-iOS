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

    // Content management
    @State private var selectedContent: [ContentItem] = []
    @StateObject private var contentManager = ContentManager.shared

    // Scheduling
    @State private var shouldSchedule = false
    @State private var scheduleDate = Date()

    // Feedback for the user
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isUploading = false

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

                        // Media attachments section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Attachments")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            UploadMediaView(selectedContent: $selectedContent)
                        }

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
                        Button(action: {
                            Task {
                                await saveSIF()
                            }
                        }) {
                            HStack {
                                if isUploading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                }
                                Text(isUploading ? "Uploading..." : "Send SIF")
                            }
                        }
                        .buttonStyle(PrimaryActionButtonStyle())
                        .disabled(isUploading)
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

        isUploading = true

        // Upload content items first
        var uploadedContentItems: [ContentItem] = []
        for contentItem in selectedContent {
            do {
                let uploadedItem = try await contentManager.uploadContent(contentItem)
                uploadedContentItems.append(uploadedItem)
            } catch {
                showAlert(title: "Upload Error", message: "Failed to upload \(contentItem.displayName): \(error.localizedDescription)")
                isUploading = false
                return
            }
        }

        var newSif = SIFItem(
            authorUid: authorUid,
            recipients: recipientList,
            subject: subject,
            message: message,
            createdDate: Date(),
            scheduledDate: shouldSchedule ? scheduleDate : Date()
        )
        
        // Add uploaded content
        newSif.contentItems = uploadedContentItems

        let db = Firestore.firestore()
        do {
            // The 'from' parameter requires SIFItem to conform to Codable
            try db.collection("sifs").addDocument(from: newSif)
            showAlert(title: "Success!", message: "Your SIF has been saved and is scheduled for delivery.")
            
            // Clear form fields
            singleRecipient = ""
            multipleRecipients = ""
            subject = ""
            message = ""
            selectedContent = []
            shouldSchedule = false
            scheduleDate = Date()
            
        } catch let error {
            showAlert(title: "Error", message: "There was an issue saving your SIF: \(error.localizedDescription)")
        }
        
        isUploading = false
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
