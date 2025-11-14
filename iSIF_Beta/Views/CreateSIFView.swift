import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct CreateSIFView: View {

    @EnvironmentObject var router: TabRouter
    @EnvironmentObject var authState: AuthState

    // MARK: - Core Fields
    @State private var subject: String = ""
    @State private var messageText: String = ""
    @State private var signatureData: Data? = nil
    @State private var selectedTemplate: TemplateModel? = nil
    @State private var deliveryType: DeliveryType = .oneToOne
    @State private var scheduledDate: Date? = nil
    @State private var showDatePicker = false

    // MARK: - UI State
    @State private var showSignatureSheet = false
    @State private var showValidationAlert = false
    @State private var showToast = false
    @State private var showFriendPicker = false
    @State private var showConfirmation = false
    @State private var isNavVisible = true
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var sentSIF: SIF?
    @State private var selectedFriends: [SIFRecipient] = []
    @State private var showGroupPicker = false
    @State private var attachments: [URL] = []
    @State private var showDocumentPicker = false
    @State private var showImagePicker = false

    private let friendsService: FriendsProviding = FriendService()
    private let sifService: SIFProviding = SIFService.shared

    var body: some View {
        ZStack(alignment: .bottom) {
            
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.0, green: 0.796, blue: 1.0),
                    Color.white
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    
                    headerSection
                    deliveryTypeSection
                    recipientSection
                    schedulingSection
                    templateSection
                    
                    // Show selected template preview if available
                    if let selectedTemplate = selectedTemplate {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Selected Template")
                                .font(.custom("AvenirNext-DemiBold", size: 16))
                            
                            HStack {
                                Image(systemName: selectedTemplate.icon ?? "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 40, height: 40)
                                    .foregroundColor(.black.opacity(0.8))
                                    .padding(8)
                                    .background(selectedTemplate.color)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                
                                VStack(alignment: .leading) {
                                    Text(selectedTemplate.title)
                                        .font(.custom("AvenirNext-DemiBold", size: 14))
                                        .foregroundColor(.black)
                                    Text(selectedTemplate.subtitle)
                                        .font(.custom("AvenirNext-Regular", size: 12))
                                        .foregroundColor(.black.opacity(0.7))
                                        .lineLimit(2)
                                }
                                
                                Spacer()
                                
                                Button("Remove") {
                                    self.selectedTemplate = nil
                                }
                                .font(.custom("AvenirNext-Regular", size: 12))
                                .foregroundColor(.red)
                            }
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(12)
                        }
                    }
                    
                    messageSection
                    signatureSection
                    attachmentsSection
                    toneEmotionSection
                    sendButton
                }
                .padding(.bottom, 120)
                .padding(.horizontal, 20)
            }
            
            // Bottom Nav
            BottomNavBar(
                selectedTab: $router.selectedTab,
                isVisible: $isNavVisible
            )
            .environmentObject(router)
            .environmentObject(authState)
            .padding(.bottom, 8)
            
            if showToast {
                successToast
            }
            
            if isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                ProgressView("Sending SIF...")
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
            }
        }
        .navigationBarHidden(true)
        
        // MARK: - Signature Sheet
        .sheet(isPresented: $showSignatureSheet) {
            SignatureView(isPresented: $showSignatureSheet) { sig in
                self.signatureData = sig.signatureImageData
            }
            .environmentObject(router)
            .environmentObject(authState)
        }
        
        .sheet(isPresented: $showFriendPicker) {
            FriendPickerSheet(deliveryType: deliveryType, selected: $selectedFriends)
                .environmentObject(router)
                .environmentObject(authState)
        }
        
        .sheet(isPresented: $showGroupPicker) {
            GroupPickerView(selectedFriends: $selectedFriends)
                .environmentObject(router)
                .environmentObject(authState)
        }
        
        .fileImporter(
            isPresented: $showDocumentPicker,
            allowedContentTypes: [.item],
            allowsMultipleSelection: true
        ) { result in
            handleDocumentPickerResult(result)
        }
        
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(attachments: $attachments)
        }
        
        // MARK: - Confirmation Navigation
        .sheet(isPresented: $showConfirmation) {
            if let sentSIF = sentSIF {
                SIFConfirmationView( sif: sentSIF)
            }
        }
        
        // MARK: - Validation Alert
        .alert("Missing Information", isPresented: $showValidationAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please fill out all required fields before sending.")
        }
        
        // MARK: - Error Alert
        .alert("Error", isPresented: .init(get: { errorMessage != nil }, set: { _ in errorMessage = nil })) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
        
        // ✅ WORKING Template Autofill
        .onChange(of: selectedTemplate, initial: false) { oldValue, newValue in
            if let tmpl = newValue {
                messageText = tmpl.subtitle
            }
        }
        
        // Enforce delivery type constraints
        .onChange(of: deliveryType) { oldValue, newValue in
            if newValue == .oneToOne && selectedFriends.count > 1 {
                selectedFriends = Array(selectedFriends.prefix(1))
            }
        }
    }
    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Compose Your SIF")
                .font(.custom("AvenirNext-DemiBold", size: 24))
                .foregroundColor(Color(hex: "132E37"))

            Text("Craft your message, add your tone, and express yourself beautifully.")
                .font(.custom("AvenirNext-Regular", size: 15))
                .foregroundColor(.black.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }

    // MARK: - Delivery Type
    private var deliveryTypeSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Delivery Type")
                .font(.custom("AvenirNext-DemiBold", size: 16))

            Picker("Delivery Type", selection: $deliveryType) {
                Text(String.oneToOne.displayTitle).tag(String.oneToOne)
                Text(String.oneToMany.displayTitle).tag(String.oneToMany)
                Text(String.toGroup.displayTitle).tag(String.toGroup)
            }
            .pickerStyle(.segmented)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Recipient
    private var recipientSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Send To")
                .font(.custom("AvenirNext-DemiBold", size: 16))

            Button {
                if deliveryType == .toGroup {
                    showGroupPicker = true
                } else {
                    showFriendPicker = true
                }
            } label: {
                HStack {
                    if selectedFriends.isEmpty {
                        Text(deliveryType == .toGroup ? "Choose Group" : "Choose Recipients")
                            .foregroundColor(.gray)
                    } else {
                        Text("\(selectedFriends.count) recipient(s) selected")
                            .foregroundColor(.black)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.white.opacity(0.9))
                .cornerRadius(12)
            }

            if !selectedFriends.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(selectedFriends) { recipient in
                        Text("• \(recipient.name) (\(recipient.email))")
                            .font(.caption)
                            .foregroundColor(.black.opacity(0.7))
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }

    // MARK: - Scheduling
    private var schedulingSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Delivery Schedule")
                .font(.custom("AvenirNext-DemiBold", size: 16))

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showDatePicker.toggle()
                }
            } label: {
                HStack {
                    if let scheduledDate = scheduledDate {
                        Text("Scheduled for \(scheduledDate.formatted(date: .abbreviated, time: .shortened))")
                            .foregroundColor(.black)
                    } else {
                        Text("Schedule for later")
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Image(systemName: "calendar")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.white.opacity(0.9))
                .cornerRadius(12)
            }

            if showDatePicker {
                VStack {
                    DatePicker(
                        "Select delivery date",
                        selection: Binding(
                            get: { scheduledDate ?? Date().addingTimeInterval(24 * 3600) },
                            set: { scheduledDate = $0 }
                        ),
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(12)

                    HStack {
                        Button("Clear Schedule") {
                            scheduledDate = nil
                            showDatePicker = false
                        }
                        .foregroundColor(.red)
                        .padding(.horizontal)

                        Spacer()

                        Button("Done") {
                            showDatePicker = false
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal)
                    }
                    .padding(.top, 8)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
    }

    // MARK: - Templates
    private var templateSection: some View {
        VStack(alignment: .leading, spacing: 6) {

            Text("Templates")
                .font(.custom("AvenirNext-DemiBold", size: 16))

            NavigationLink {
                TemplateGalleryView(selectedTemplate: $selectedTemplate)
                    .environmentObject(router)
                    .environmentObject(authState)
            } label: {
                HStack {
                    Text("Explore SIF templates to speed up your message creation.")
                        .font(.custom("AvenirNext-Regular", size: 14))
                        .foregroundColor(.black.opacity(0.75))

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.white.opacity(0.9))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
            }
        }
    }

    // MARK: - Message
    private var messageSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Your Message")
                .font(.custom("AvenirNext-DemiBold", size: 16))

            TextEditor(text: $messageText)
                .frame(height: 160)
                .padding()
                .background(Color.white.opacity(0.9))
                .cornerRadius(12)
        }
    }

    // MARK: - Signature
    private var signatureSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Signature")
                .font(.custom("AvenirNext-DemiBold", size: 16))
            
            Button {
                showSignatureSheet = true
            } label: {
                HStack {
                    if signatureData != nil {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                    
                    Text(signatureData == nil ? "Add Signature" : "Signature Added")
                        .font(.custom("AvenirNext-Regular", size: 15))
                        .foregroundColor(.black)

                    Spacer()

                    Image(systemName: "pencil")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.white.opacity(0.9))
                .cornerRadius(12)
            }
            
            if signatureData != nil {
                Text("Signature will be included with your SIF")
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(.horizontal, 4)
            }
        }
    }

    // MARK: - Attachments
    private var attachmentsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Attachments")
                .font(.custom("AvenirNext-DemiBold", size: 16))
            
            HStack {
                Button("Attach Document") {
                    showDocumentPicker = true
                }
                .buttonStyle(AttachmentButtonStyle())
                
                Button("Attach Photo") {
                    showImagePicker = true
                }
                .buttonStyle(AttachmentButtonStyle())
            }
            
            if !attachments.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Attached Files:")
                        .font(.caption)
                        .foregroundColor(.black.opacity(0.7))
                    ForEach(attachments, id: \.self) { url in
                        Text("• \(url.lastPathComponent)")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    // MARK: - Tone/Emotion (placeholder)
    private var toneEmotionSection: some View {
        Text("Tone & Emotion Section")
            .font(.system(size: 16))
            .foregroundColor(.gray)
    }

    // MARK: - Send Button
    private var sendButton: some View {
        Button {
            if selectedFriends.isEmpty || messageText.isEmpty {
                showValidationAlert = true
                return
            }

            Task {
                await sendSIF()
            }

        } label: {
            Text("Send SIF")
                .font(.custom("AvenirNext-DemiBold", size: 17))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(hex: "132E37"))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
        }
        .padding(.top, 10)
    }

    private func sendSIF() async {
        // Use authState for user ID to avoid Firebase dependency in previews
        let userUID = authState.uid ?? "preview-user"
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Upload signature if available
            var signatureURLString: String? = nil
            if let signatureData = signatureData {
                let signatureURL = try await SignatureStore.save(imageData: signatureData, for: userUID)
                signatureURLString = signatureURL.absoluteString
            }
            
            let sif = SIF(
                senderUID: userUID,
                recipients: selectedFriends,
                subject: subject.isEmpty ? nil : subject,
                message: messageText,
                deliveryType: deliveryType.rawValue,
                deliveryChannel: "inApp",
                deliveryDate: scheduledDate,
                createdAt: Date(),
                status: scheduledDate != nil ? "scheduled" : "sent",
                signatureURLString: signatureURLString,
                attachments: nil,
                templateName: selectedTemplate?.id,
                textOverlay: nil
            )
            
            // Use SIFDataManager directly instead of sifService
            try await SIFDataManager.shared.saveSIF(sif)
            sentSIF = sif
            showConfirmation = true
            
            // Clear form
            subject = ""
            messageText = ""
            selectedFriends = []
            selectedTemplate = nil
            signatureData = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Toast
    private var successToast: some View {
        Text("SIF Sent ✓")
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 26)
            .padding(.vertical, 12)
            .background(Capsule().fill(Color.green.opacity(0.9)))
            .shadow(radius: 4)
            .padding(.bottom, 80)
    }
    
    // MARK: - Document Picker Handler
    private func handleDocumentPickerResult(_ result: Result<[URL], Error>) {
        do {
            let selectedFiles = try result.get()
            attachments.append(contentsOf: selectedFiles)
        } catch {
            errorMessage = "Failed to import documents: \(error.localizedDescription)"
        }
    }
}

// MARK: - Group Picker View
struct GroupPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var router: TabRouter
    @EnvironmentObject var authState: AuthState
    @Binding var selectedFriends: [SIFRecipient]
    
    // Sample groups - in a real app, these would come from a service
    private let sampleGroups: [GroupModel] = [
        GroupModel(
            name: "Family",
            members: [
                SIFRecipient(id: "1", name: "John Doe", email: "john@example.com"),
                SIFRecipient(id: "2", name: "Jane Doe", email: "jane@example.com")
            ]
        ),
        GroupModel(
            name: "Friends", 
            members: [
                SIFRecipient(id: "3", name: "Alice Smith", email: "alice@example.com"),
                SIFRecipient(id: "4", name: "Bob Johnson", email: "bob@example.com")
            ]
        )
    ]
    
    var body: some View {
        NavigationView {
            List(sampleGroups) { group in
                Button(action: {
                    selectedFriends = group.members
                    dismiss()
                }) {
                    VStack(alignment: .leading) {
                        Text(group.name)
                            .font(.headline)
                        Text("\(group.members.count) members")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Select Group")
            .navigationBarItems(trailing: Button("Cancel") { dismiss() })
        }
    }
}

// MARK: - Group Model
struct GroupModel: Identifiable {
    let id = UUID().uuidString
    let name: String
    let members: [SIFRecipient]
}

// MARK: - Image Picker (UIKit-based)
struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    @Binding var attachments: [URL]
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let imageURL = info[.imageURL] as? URL {
                parent.attachments.append(imageURL)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Attachment Button Style
struct AttachmentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.custom("AvenirNext-Regular", size: 14))
            .foregroundColor(.blue)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
    }
}

struct CreateSIFView_PreviewWrapper: View {
    @StateObject private var authState = AuthState()
    @StateObject private var tabRouter = TabRouter()

    var body: some View {
        CreateSIFView()
            .environmentObject(authState)
            .environmentObject(tabRouter)
            .onAppear { authState.uid = "preview-user" }
    }
}

#if DEBUG
struct CreateSIFView_Previews: PreviewProvider {
    static var previews: some View {
        CreateSIFView_PreviewWrapper()
    }
}
#endif
