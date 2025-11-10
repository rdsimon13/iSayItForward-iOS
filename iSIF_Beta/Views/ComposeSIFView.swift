import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ComposeSIFView: View {
    @EnvironmentObject var authState: AuthState
    @EnvironmentObject var router: TabRouter
    
    private let sifService = SIFService()
    private let friendService = FriendService()
    
    // MARK: - Optional Editing Context
    var existingSIF: SIF?
    var isEditing: Bool = false
    var isResend: Bool = false
    
    // MARK: - State Variables
    @State private var message = ""
    @State private var tone = "Supportive"
    @State private var emotion = "Joyful"
    @State private var deliveryType = "One-to-One"
    @State private var selectedFriends: [UserFriend] = []
    
    @State private var selectedTemplate: TemplateModel? = nil
    
    @State private var showTemplateGallery = false
    @State private var showSignatureView = false
    @State private var savedSignature: UIImage?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isSending = false
    @State private var showFriendPicker = false
    @State private var showConfirmation = false
    @State private var sentSIF: SIF?
    
    // ✅ Mock templates: these match your TemplateModel
    @State private var mockTemplates: [TemplateModel] = [
        TemplateModel(id: UUID().uuidString, title: "Sunset Bliss",  subtitle: "Warm, gentle, reflective", imageName: "sunset_placeholder", color: <#Color#>),
        TemplateModel(id: UUID().uuidString, title: "Ocean Whisper", subtitle: "Calming, cool, peaceful",   imageName: "ocean_placeholder", color: <#Color#>),
        TemplateModel(id: UUID().uuidString, title: "Minimal Calm",  subtitle: "Simple, clean, modern",    imageName: "calm_placeholder", color: <#Color#>)
    ]
    
    init(existingSIF: SIF? = nil, isEditing: Bool = false, isResend: Bool = false) {
        self.existingSIF = existingSIF
        self.isEditing = isEditing
        self.isResend = isResend
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                
                GradientTheme.welcomeBackground
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 30) {
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
                }
                
                NavigationLink(
                    destination: SIFConfirmationView(sif: sentSIF ?? placeholderSIF)
                        .environmentObject(router)
                        .environmentObject(authState),
                    isActive: $showConfirmation
                ) { EmptyView() }
                
                VStack {
                    Spacer()
                    BottomNavBar(
                        selectedTab: $router.selectedTab,
                        isVisible: .constant(true)
                    )
                    .environmentObject(router)
                    .environmentObject(authState)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear(perform: populateIfEditing)
        
        // MARK: Sheets
        .sheet(isPresented: $showFriendPicker) {
            FriendPickerView(selectedFriends: $selectedFriends, deliveryType: deliveryType)
                .presentationDetents([.medium, .large])
                .environmentObject(router)
                .environmentObject(authState)
        }
        .sheet(isPresented: $showTemplateGallery) {
            TemplateGalleryView(selectedTemplate: $selectedTemplate)
                .environmentObject(router)
                .environmentObject(authState)
        }
        .sheet(isPresented: $showSignatureView) {
            SignatureView(isPresented: $showSignatureView) { sig in
                if let image = UIImage(data: sig.signatureImageData) {
                    savedSignature = image
                }
            }
            .environmentObject(router)
            .environmentObject(authState)
        }
        
        // MARK: Alerts
        .alert("SIF Composer", isPresented: $showingAlert) {
            Button("OK") {}
        } message: {
            Text(alertMessage)
        }
        
        // MARK: Autofill message from template
        .onChange(of: selectedTemplate) { newValue in
            if let tmpl = newValue, !tmpl.subtitle.isEmpty {
                message = tmpl.subtitle
            }
        }
    }
    
    // MARK: - Prefill
    private func populateIfEditing() {
        guard let sif = existingSIF else { return }
        message = sif.message
        tone = sif.tone ?? "Supportive"
        emotion = sif.emotion ?? "Joyful"
        deliveryType = sif.deliveryType
        selectedFriends = sif.recipients.map {
            UserFriend(id: UUID().uuidString, name: $0.name, email: $0.email)
        }
    }
    
    // MARK: Header
    private var headerSection: some View {
        VStack(spacing: 10) {
            Image("isiFLogo")
                .resizable()
                .scaledToFit()
                .frame(height: 90)
                .shadow(color: .black.opacity(0.3), radius: 5, y: 3)
            
            Text(isEditing ? "Edit Your SIF" :
                 isResend ? "Re-Send Your SIF" :
                 "Compose Your SIF")
            .font(.custom("AvenirNext-DemiBold", size: 24))
            .foregroundColor(Color(hex: "132E37"))
        }
        .padding(.top, 40)
    }
    
    // MARK: Delivery Type
    private var deliveryTypeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Delivery Type")
                .font(.custom("AvenirNext-Regular", size: 16))
                .foregroundColor(.gray)
                .padding(.leading)
            
            HStack(spacing: 12) {
                deliveryTypeButton("One-to-One")
                deliveryTypeButton("One-to-Many")
                deliveryTypeButton("Group")
            }
            .padding(.horizontal)
        }
    }
    
    private func deliveryTypeButton(_ type: String) -> some View {
        Button {
            deliveryType = type
            selectedFriends.removeAll()
        } label: {
            Text(type)
                .font(.custom("AvenirNext-Regular", size: 15))
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(
                    Capsule()
                        .fill(deliveryType == type ? Color.blue.opacity(0.8) : Color.white.opacity(0.9))
                )
                .foregroundColor(deliveryType == type ? .white : .black)
                .shadow(radius: deliveryType == type ? 3 : 0)
        }
    }
    
    // MARK: Recipients
    private var recipientSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Recipient\(deliveryType == "One-to-Many" ? "s" : "")")
                    .font(.custom("AvenirNext-Regular", size: 16))
                    .foregroundColor(.gray)
                
                Spacer()
                Button {
                    showFriendPicker = true
                } label: {
                    Label("Select", systemImage: "person.crop.circle.badge.plus")
                        .font(.custom("AvenirNext-Regular", size: 14))
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            if selectedFriends.isEmpty {
                Text("No recipients selected.")
                    .font(.custom("AvenirNext-Regular", size: 14))
                    .foregroundColor(.gray)
                    .padding(.horizontal)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(selectedFriends, id: \.id) { friend in
                            Capsule()
                                .fill(Color.white.opacity(0.9))
                                .overlay(
                                    Text(friend.name)
                                        .font(.custom("AvenirNext-Regular", size: 14))
                                        .foregroundColor(.black.opacity(0.8))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                )
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    // MARK: - Template Section
    private var templateSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Select a Template")
                .font(.custom("AvenirNext-Regular", size: 16))
                .foregroundColor(.gray)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(mockTemplates, id: \.id) { template in
                        VStack {

                            // ✅ FIXED — ALWAYS VALID, NO PLACEHOLDER
                            Image(template.imageName ?? <#default value#>)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            selectedTemplate?.id == template.id
                                                ? Color.blue
                                                : Color.clear,
                                            lineWidth: 3
                                        )
                                )
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        selectedTemplate = template
                                    }
                                }

                            Text(template.title)
                                .font(.custom("AvenirNext-Regular", size: 12))
                                .foregroundColor(.black.opacity(0.7))
                        }
                    }
                }
                .padding(.horizontal)
            }

            Button {
                showTemplateGallery = true
            } label: {
                Label("🌅 Explore Full Gallery", systemImage: "photo.on.rectangle")
                    .font(.custom("AvenirNext-DemiBold", size: 14))
                    .foregroundColor(.blue)
                    .padding(.horizontal)
            }
        }
    }
    // MARK: Message Section
    private var messageSection: some View {
        ZStack {
            if let selectedTemplate = selectedTemplate {
                Image(selectedTemplate.imageName!)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .clipped()
                    .blur(radius: 5)
                    .overlay(Color.white.opacity(0.75))
                    .cornerRadius(20)
                    .shadow(radius: 4, y: 2)
            } else {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.9))
                    .shadow(radius: 4, y: 2)
                    .frame(height: 200)
            }
            
            TextEditor(text: $message)
                .padding()
                .frame(height: 200)
                .cornerRadius(20)
                .font(.custom("AvenirNext-Regular", size: 16))
                .foregroundColor(.black)
                .background(Color.clear)
                .padding(.horizontal)
        }
    }
    
    // MARK: Signature Section
    private var signatureSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Signature")
                .font(.custom("AvenirNext-Regular", size: 16))
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            if let savedSignature = savedSignature {
                Image(uiImage: savedSignature)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(radius: 3, y: 2)
                    .padding(.horizontal)
            }
            
            Button {
                showSignatureView = true
            } label: {
                Label("Add Signature ✍️", systemImage: "pencil.tip.crop.circle.badge.plus")
                    .font(.custom("AvenirNext-DemiBold", size: 15))
                    .foregroundColor(.blue)
                    .padding(.horizontal)
            }
        }
    }
    
    // MARK: Tone & Emotion
    private var toneEmotionSection: some View {
        VStack(spacing: 18) {
            HStack(spacing: 16) {
                selectButton("Supportive", selected: tone == "Supportive") { tone = "Supportive" }
                selectButton("Motivational", selected: tone == "Motivational") { tone = "Motivational" }
            }
            HStack(spacing: 16) {
                selectButton("Joyful", selected: emotion == "Joyful") { emotion = "Joyful" }
                selectButton("Calm", selected: emotion == "Calm") { emotion = "Calm" }
            }
        }
        .padding(.horizontal)
    }
    
    private func selectButton(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.custom("AvenirNext-Regular", size: 15))
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .background(
                    Capsule().fill(selected ? Color.yellow.opacity(0.7) : Color.white.opacity(0.9))
                )
                .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                .foregroundColor(.black)
        }
    }
    
    // MARK: Send Button
    private var sendButton: some View {
        Button(action: sendSIF) {
            HStack {
                if isSending { ProgressView() }
                Text(isSending ? "Sending..." : "Deliver Your SIF ✉️")
                    .font(.custom("AvenirNext-DemiBold", size: 18))
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.green.opacity(0.8))
            .foregroundColor(.white)
            .cornerRadius(25)
        }
        .disabled(isSending)
        .padding(.horizontal, 40)
        .padding(.top, 10)
    }
    
    // MARK: Send Logic
    private func sendSIF() {
        guard !message.isEmpty else {
            alertMessage = "Please compose your SIF before sending."
            showingAlert = true
            return
        }
        
        guard !selectedFriends.isEmpty else {
            alertMessage = "Please select at least one recipient."
            showingAlert = true
            return
        }
        
        guard let userId = Auth.auth().currentUser?.uid else {
            alertMessage = "You must be logged in to send a SIF."
            showingAlert = true
            return
        }
        
        Task {
            isSending = true
            
            do {
                let recipients = selectedFriends.map {
                    SIFRecipient(id: UUID().uuidString, name: $0.name, email: $0.email)
                }
                
                let sif = SIF(
                    senderId: userId,
                    recipients: recipients,
                    subject: "My SIF",
                    message: message,
                    category: "General",
                    tone: tone,
                    emotion: emotion,
                    templateId: selectedTemplate?.id,
                    documentURL: nil,
                    deliveryType: deliveryType,
                    isScheduled: false,
                    scheduledDate: nil,
                    createdAt: Date(),
                    status: "sent"
                )
                
                try await sifService.sendSIF(sif, for: userId)
                
                sentSIF = sif
                showConfirmation = true
                
            } catch {
                alertMessage = "Failed to send SIF: \(error.localizedDescription)"
                showingAlert = true
            }
            
            isSending = false
        }
    }
    
    // MARK: - Placeholder SIF
    private var placeholderSIF: SIF {
        SIF(
            senderId: "demoUser",
            recipients: [
                SIFRecipient(id: UUID().uuidString, name: "Placeholder Recipient", email: "placeholder@example.com")
            ],
            subject: "Demo Subject",
            message: "This is a placeholder SIF.",
            category: "General",
            tone: "Supportive",
            emotion: "Joyful",
            templateId: nil,
            documentURL: nil,
            deliveryType: "One-to-One",
            isScheduled: false,
            scheduledDate: nil,
            createdAt: Date(),
            status: "draft"
        )
    }
    
    #Preview {
        ComposeSIFView()
            .environmentObject(AuthState())
            .environmentObject(TabRouter())
    }
}
