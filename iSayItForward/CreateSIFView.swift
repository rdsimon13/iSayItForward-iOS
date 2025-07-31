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

    // Scheduling
    @State private var shouldSchedule = false
    @State private var scheduleDate = Date()

    // Feedback for the user
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    // Send options sheet
    @State private var showingSendOptions = false
    @State private var currentSIF: SIFItem?

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
                            // Create a SIF and trigger the send options
                            let newSif = SIFItem(
                                authorUid: Auth.auth().currentUser?.uid ?? "",
                                recipients: getRecipientList(),
                                subject: subject,
                                message: message,
                                createdDate: Date(),
                                scheduledDate: shouldSchedule ? scheduleDate : Date(),
                                isScheduled: shouldSchedule
                            )
                            
                            // Save first, then trigger send options
                            saveSIFWithSendOptions(newSif)
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
            .sheet(isPresented: $showingSendOptions) {
                if let sif = currentSIF {
                    SendOptionsView(sif: .constant(sif))
                }
            }
        }
    }

    // MARK: - Firestore Logic
    
    func getRecipientList() -> [String] {
        switch recipientMode {
        case .single:
            return singleRecipient.isEmpty ? [] : [singleRecipient]
        case .multiple:
            return multipleRecipients.isEmpty ? [] : multipleRecipients.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
        case .group:
            return [selectedGroup]
        }
    }
    
    func saveSIFWithSendOptions(_ sif: SIFItem) {
        guard !sif.recipients.isEmpty else {
            showAlert(title: "Missing Information", message: "Please enter recipients.")
            return
        }
        
        guard !sif.subject.isEmpty else {
            showAlert(title: "Missing Information", message: "Please enter a subject.")
            return
        }
        
        guard !sif.message.isEmpty else {
            showAlert(title: "Missing Information", message: "Please enter a message.")
            return
        }
        
        let db = Firestore.firestore()
        do {
            var newSif = sif
            // Save the SIF first to get an ID
            let docRef = try db.collection("sifs").addDocument(from: newSif)
            newSif.id = docRef.documentID
            
            // Update the current SIF and show send options
            currentSIF = newSif
            showingSendOptions = true
            
        } catch let error {
            showAlert(title: "Error", message: "There was an issue saving your SIF: \(error.localizedDescription)")
        }
    }
    
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

        let newSif = SIFItem(
            authorUid: authorUid,
            recipients: recipientList,
            subject: subject,
            message: message,
            createdDate: Date(),
            scheduledDate: shouldSchedule ? scheduleDate : Date()
        )

        let db = Firestore.firestore()
        do {
            // The 'from' parameter requires SIFItem to conform to Codable
            try db.collection("sifs").addDocument(from: newSif)
            showAlert(title: "Success!", message: "Your SIF has been saved and is scheduled for delivery.")
            // You can add code here to clear the form fields if desired
        } catch let error {
            showAlert(title: "Error", message: "There was an issue saving your SIF: \(error.localizedDescription)")
        }
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
