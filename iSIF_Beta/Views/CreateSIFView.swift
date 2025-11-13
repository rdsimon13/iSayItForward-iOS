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
    @State private var selectedRecipients: [SIFRecipient] = []
    @State private var deliveryType: DeliveryType = .oneToOne

    // MARK: - UI State
    @State private var showSignatureSheet = false
    @State private var showValidationAlert = false
    @State private var showToast = false
    @State private var showRecipientPicker = false
    @State private var showConfirmation = false
    @State private var isNavVisible = true
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var sentSIF: SIF?

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
                    templateSection
                    messageSection
                    signatureSection
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
        
        // MARK: - Recipient Picker Sheet
        .sheet(isPresented: $showRecipientPicker) {
            FriendPickerView(
                deliveryType: deliveryType,
                selectedFriends: $selectedRecipients
            )
            .environmentObject(router)
            .environmentObject(authState)
        }
        
        // MARK: - Confirmation Navigation
        .sheet(isPresented: $showConfirmation) {
            if let sentSIF = sentSIF {
                ConfirmationView(sif: sentSIF)
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
            if newValue == .oneToOne && selectedRecipients.count > 1 {
                selectedRecipients = Array(selectedRecipients.prefix(1))
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
                ForEach(DeliveryType.allCases) { type in
                    Text(type.displayTitle).tag(type)
                }
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
                showRecipientPicker = true
            } label: {
                HStack {
                    if selectedRecipients.isEmpty {
                        Text("Choose Recipients")
                            .foregroundColor(.gray)
                    } else {
                        Text("\(selectedRecipients.count) recipient(s) selected")
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

            if !selectedRecipients.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(selectedRecipients) { recipient in
                        Text("• \(recipient.name) (\(recipient.email))")
                            .font(.caption)
                            .foregroundColor(.black.opacity(0.7))
                    }
                }
                .padding(.horizontal, 4)
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
        Button {
            showSignatureSheet = true
        } label: {
            HStack {
                Text(signatureData == nil ? "Add Signature" : "Edit Signature")
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
            if selectedRecipients.isEmpty || messageText.isEmpty {
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
            let sif = SIF(
                senderUID: userUID,
                recipients: selectedRecipients,
                subject: subject.isEmpty ? nil : subject,
                message: messageText,
                deliveryType: deliveryType,
                scheduledAt: nil
            )
            
            let id = try await sifService.saveSIF(sif)
            sentSIF = sif
            showConfirmation = true
            
            // Clear form
            subject = ""
            messageText = ""
            selectedRecipients = []
            selectedTemplate = nil
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

#Preview {
    CreateSIFView_PreviewWrapper()
}
