//
//  ComposeSIFView.swift
//  iSIF_Beta
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ComposeSIFView: View {
    @EnvironmentObject var authState: AuthState
    @EnvironmentObject var router: TabRouter

    // If you’re still using SIFDataManager as a shim, keep this:
    private let sifService = SIFDataManager()
    private let friendService = FriendService()

    // MARK: - Optional Editing Context
    var existingSIF: SIF?
    var isEditing: Bool = false
    var isResend: Bool = false

    // MARK: - State
    @State private var message = ""
    @State private var tone = "Supportive"     // UI-only
    @State private var emotion = "Joyful"      // UI-only

    @State private var deliveryType: DeliveryType = .oneToOne
    @State private var selectedFriends: [SIFRecipient] = []     // concrete type

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

    // Demo templates
    @State private var mockTemplates: [TemplateModel] = [
        .init(id: UUID().uuidString, title: "Sunset Bliss",  subtitle: "Warm, gentle, reflective", imageName: "sunset_placeholder", colorHex: "#FF9500"),
        .init(id: UUID().uuidString, title: "Ocean Whisper", subtitle: "Calming, cool, peaceful",  imageName: "ocean_placeholder",  colorHex: "#007AFF"),
        .init(id: UUID().uuidString, title: "Minimal Calm",  subtitle: "Simple, clean, modern",   imageName: "calm_placeholder",   colorHex: "#8E8E93"),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                GradientTheme.welcomeBackground.ignoresSafeArea()

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

                // Navigate to confirmation
                NavigationLink(
                    destination: SIFConfirmationView(sif: sentSIF ?? placeholderSIF)
                        .environmentObject(router)
                        .environmentObject(authState),
                    isActive: $showConfirmation
                ) { EmptyView() }

                // Bottom nav
                VStack { Spacer()
                    BottomNavBar(selectedTab: $router.selectedTab, isVisible: .constant(true))
                        .environmentObject(router)
                        .environmentObject(authState)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear(perform: populateIfEditing)

        // MARK: Sheets

        .sheet(isPresented: $showFriendPicker) {
            // 🚫 Do not use `coder:` initializers in SwiftUI sheets. Always present a View.
            FriendPickerView(
                deliveryType: deliveryType,
                selectedFriends: $selectedFriends
            )
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
                if let image = UIImage(data: sig.signatureImageData) { savedSignature = image }
            }
            .environmentObject(router)
            .environmentObject(authState)
        }

        // Alerts
        .alert("SIF Composer", isPresented: $showingAlert) {
            Button("OK") {}
        } message: { Text(alertMessage) }

        // Autofill from template
        .onChange(of: selectedTemplate) { newVal in
            if let t = newVal, !t.subtitle.isEmpty { message = t.subtitle }
        }
    }

    // MARK: Prefill
    private func populateIfEditing() {
        guard let sif = existingSIF else { return }
        message = sif.message
        deliveryType = sif.deliveryType
        selectedFriends = sif.recipients
    }

    // MARK: UI sections

    private var headerSection: some View {
        VStack(spacing: 10) {
            Image("isiFLogo")
                .resizable().scaledToFit().frame(height: 90)
                .shadow(color: .black.opacity(0.3), radius: 5, y: 3)

            Text(isEditing ? "Edit Your SIF" : (isResend ? "Re-Send Your SIF" : "Compose Your SIF"))
                .font(.custom("AvenirNext-DemiBold", size: 24))
                .foregroundColor(Color(hex: "132E37"))
        }
        .padding(.top, 40)
    }

    private var deliveryTypeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Delivery Type")
                .font(.custom("AvenirNext-Regular", size: 16))
                .foregroundColor(.gray)
                .padding(.leading)

            HStack(spacing: 12) {
                ForEach(DeliveryType.allCases) { type in
                    Button {
                        deliveryType = type
                        selectedFriends.removeAll()
                    } label: {
                        Text(type.displayTitle)
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
            }
            .padding(.horizontal)
        }
    }

    private var recipientSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Recipient\(deliveryType == .oneToMany ? "s" : "")")
                    .font(.custom("AvenirNext-Regular", size: 16))
                    .foregroundColor(.gray)
                Spacer()
                Button { showFriendPicker = true } label: {
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
                        ForEach(selectedFriends, id: \.id) { f in
                            Capsule()
                                .fill(Color.white.opacity(0.9))
                                .overlay(
                                    Text(f.name)
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

    private var templateSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Select a Template")
                .font(.custom("AvenirNext-Regular", size: 16))
                .foregroundColor(.gray)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(mockTemplates, id: \.id) { t in
                        VStack {
                            Image(t.imageName ?? "photo")
                                .resizable().scaledToFill()
                                .frame(width: 100, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedTemplate?.id == t.id ? Color.blue : .clear, lineWidth: 3)
                                )
                                .onTapGesture { withAnimation(.easeInOut(duration: 0.3)) { selectedTemplate = t } }

                            Text(t.title)
                                .font(.custom("AvenirNext-Regular", size: 12))
                                .foregroundColor(.black.opacity(0.7))
                        }
                    }
                }
                .padding(.horizontal)
            }

            Button { showTemplateGallery = true } label: {
                Label("🌅 Explore Full Gallery", systemImage: "photo.on.rectangle")
                    .font(.custom("AvenirNext-DemiBold", size: 14))
                    .foregroundColor(.blue)
                    .padding(.horizontal)
            }
        }
    }

    private var messageSection: some View {
        ZStack {
            if let t = selectedTemplate, let img = t.imageName {
                Image(img)
                    .resizable().scaledToFill()
                    .frame(height: 200).clipped()
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

    private var signatureSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Signature")
                .font(.custom("AvenirNext-Regular", size: 16))
                .foregroundColor(.gray)
                .padding(.horizontal)

            if let img = savedSignature {
                Image(uiImage: img)
                    .resizable().scaledToFit().frame(height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(radius: 3, y: 2)
                    .padding(.horizontal)
            }

            Button { showSignatureView = true } label: {
                Label("Add Signature ✍️", systemImage: "pencil.tip.crop.circle.badge.plus")
                    .font(.custom("AvenirNext-DemiBold", size: 15))
                    .foregroundColor(.blue)
                    .padding(.horizontal)
            }
        }
    }

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
                .background(Capsule().fill(selected ? Color.yellow.opacity(0.7) : Color.white.opacity(0.9)))
                .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                .foregroundColor(.black)
        }
    }

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

    // MARK: Send
    private func sendSIF() {
        guard !message.isEmpty else { alertMessage = "Please compose your SIF before sending."; showingAlert = true; return }
        guard !selectedFriends.isEmpty else { alertMessage = "Please select at least one recipient."; showingAlert = true; return }
        guard let uid = Auth.auth().currentUser?.uid else { alertMessage = "You must be logged in to send a SIF."; showingAlert = true; return }

        Task {
            isSending = true
            do {
                let sif = SIF(
                    senderUID: uid,
                    recipients: selectedFriends,
                    subject: "My SIF",
                    message: message,
                    deliveryType: deliveryType,
                    scheduledAt: nil
                )

                try await sifService.sendSIF(sif, for: uid)
                sentSIF = sif
                showConfirmation = true
            } catch {
                alertMessage = "Failed to send SIF: \(error.localizedDescription)"
                showingAlert = true
            }
            isSending = false
        }
    }

    private var placeholderSIF: SIF {
        SIF(
            senderUID: "demoUser",
            recipients: [SIFRecipient(name: "Placeholder Recipient", email: "placeholder@example.com")],
            subject: "Demo Subject",
            message: "This is a placeholder SIF.",
            deliveryType: .oneToOne,
            scheduledAt: nil
        )
    }
}
