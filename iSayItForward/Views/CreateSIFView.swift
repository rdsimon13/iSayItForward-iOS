import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

struct CreateSIFView: View {
    // MARK: - Prefill (optional)
    private let preloadedSubject: String?
    private let preloadedMessage: String?
    private let preloadedImageName: String?

    // MARK: - State
    @State private var recipientInput: String = ""
    @State private var subject: String = ""
    @State private var message: String = ""
    @State private var scheduleForLater: Bool = false
    @State private var selectedTab = "Single"
    @State private var showSignatureView = false
    @State private var savedSignature: SignatureData? = nil
    @State private var isSending = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    private let db = Firestore.firestore()

    // MARK: - Init
    init(
        preloadedSubject: String? = nil,
        preloadedMessage: String? = nil,
        preloadedImageName: String? = nil
    ) {
        self.preloadedSubject = preloadedSubject
        self.preloadedMessage = preloadedMessage
        self.preloadedImageName = preloadedImageName
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                RadialGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(red: 0.0, green: 0.796, blue: 1.0), location: 0.0),
                        .init(color: Color.white, location: 1.0)
                    ]),
                    center: .top,
                    startRadius: 0,
                    endRadius: UIScreen.main.bounds.height
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // MARK: - Prefill on appear
                        HeaderTabs(selectedTab: $selectedTab)
                            .onAppear {
                                if subject.isEmpty { subject = preloadedSubject ?? "" }
                                if message.isEmpty { message = preloadedMessage ?? "" }
                            }

                        // MARK: - Recipient
                        CapsuleField(
                            placeholder: "Recipient’s Email or Phone",
                            text: $recipientInput,
                            secure: false
                        )
                        .padding(.horizontal)

                        // MARK: - Optional Template Image
                        if let img = preloadedImageName, UIImage(named: img) != nil {
                            Image(img)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 220)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: .black.opacity(0.1), radius: 6, y: 3)
                                .padding(.horizontal)
                        }

                        // MARK: - Subject & Message
                        CapsuleField(placeholder: "Subject", text: $subject, secure: false)
                            .padding(.horizontal)
                        MessageField(message: $message)

                        // MARK: - Schedule Option
                        ScheduleToggle(scheduleForLater: $scheduleForLater)

                        // MARK: - Enhancements
                        EnhancementSection(showSignatureView: $showSignatureView)

                        // MARK: - Signature Preview
                        if let signature = savedSignature {
                            SignaturePreviewView(signatureData: signature)
                                .padding(.horizontal)
                        }

                        // MARK: - Send Button
                        Button(action: { Task { await sendSIF() } }) {
                            if isSending {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(hex: "FFD700"))
                                    .clipShape(Capsule())
                                    .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                            } else {
                                Text("Send SIF")
                                    .font(.custom("Kodchasan-Bold", size: 18))
                                    .foregroundColor(Color.black.opacity(0.85))
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color(hex: "FFD700"))
                                    .clipShape(Capsule())
                                    .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                            }
                        }
                        .disabled(isSending)
                        .padding(.horizontal)
                        .padding(.bottom, 60)
                    }
                    .padding(.top, 30)
                }
            }
            .navigationTitle("Create a SIF")
            .navigationBarTitleDisplayMode(.inline)
            .alert("SIF Status", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $showSignatureView) {
                SignatureView(isPresented: $showSignatureView) { signature in
                    savedSignature = signature
                }
            }
        }
    }

    // MARK: - Async SIF Sending Logic
    private func sendSIF() async {
        guard !recipientInput.isEmpty, !message.isEmpty else {
            alertMessage = "Please fill out all required fields."
            showAlert = true
            return
        }

        guard let sender = Auth.auth().currentUser else {
            alertMessage = "User not authenticated."
            showAlert = true
            return
        }

        isSending = true
        defer { isSending = false }

        do {
            let usersRef = db.collection("users")

            // Try finding a recipient by email or phone
            var recipientUID: String?

            let emailQuery = try await usersRef
                .whereField("email", isEqualTo: recipientInput.lowercased())
                .getDocuments()
            if let doc = emailQuery.documents.first {
                recipientUID = doc.documentID
            } else {
                let phoneQuery = try await usersRef
                    .whereField("phone", isEqualTo: recipientInput)
                    .getDocuments()
                if let doc = phoneQuery.documents.first {
                    recipientUID = doc.documentID
                }
            }

            if let recipientUID = recipientUID {
                // ✅ Recipient found: send SIF internally
                let sifData: [String: Any] = [
                    "senderUID": sender.uid,
                    "recipientUID": recipientUID,
                    "subject": subject,
                    "message": message,
                    "timestamp": Timestamp(),
                    "scheduleForLater": scheduleForLater,
                    "signatureAttached": savedSignature != nil
                ]

                // Save for sender
                try await db.collection("sifs").document(sender.uid)
                    .collection("sent").addDocument(data: sifData)

                // Save to recipient inbox
                try await db.collection("inbox").document(recipientUID)
                    .collection("received").addDocument(data: sifData)

                alertMessage = "✅ SIF successfully sent to user!"
            } else {
                // ❌ No user found — send invite instead
                await sendInviteToNonUser(recipientInput)
                alertMessage = "📨 User not found. Invite sent to \(recipientInput)."
            }

        } catch {
            alertMessage = "❌ Error sending SIF: \(error.localizedDescription)"
        }

        showAlert = true
    }

    // MARK: - Placeholder Invite Function
    private func sendInviteToNonUser(_ recipient: String) async {
        print("📬 Invite email or SMS sent to \(recipient)")
    }
}
// MARK: - Supporting Components

private struct HeaderTabs: View {
    @Binding var selectedTab: String
    let tabs = ["Single", "Multiple", "Group"]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(tabs, id: \.self) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    Text(tab)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(
                            Capsule()
                                .fill(selectedTab == tab ? Color.white : Color.white.opacity(0.3))
                                .shadow(color: selectedTab == tab ? .black.opacity(0.15) : .clear, radius: 3, y: 2)
                        )
                        .foregroundColor(selectedTab == tab ? .black : .gray)
                }
            }
        }
        .padding(.horizontal)
    }
}

private struct MessageField: View {
    @Binding var message: String
    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.95))
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)

            TextEditor(text: $message)
                .scrollContentBackground(.hidden)
                .padding()
                .frame(minHeight: 140)
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(.black)

            if message.isEmpty {
                Text("Write your message here...")
                    .foregroundColor(.gray)
                    .font(.system(size: 15))
                    .padding(.horizontal, 22)
                    .padding(.vertical, 18)
            }
        }
        .padding(.horizontal)
    }
}

private struct ScheduleToggle: View {
    @Binding var scheduleForLater: Bool
    var body: some View {
        HStack {
            Text("Schedule for later")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(.black.opacity(0.75))
            Spacer()
            Toggle("", isOn: $scheduleForLater)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: .blue))
        }
        .padding()
        .background(Color.white.opacity(0.9))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        .padding(.horizontal)
    }
}

private struct EnhancementSection: View {
    @Binding var showSignatureView: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Enhance Your SIF")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(Color(red: 0.1, green: 0.15, blue: 0.3))
                .padding(.horizontal)

            HStack(spacing: 16) {
                EnhancementButton(title: "Templates", systemIcon: "doc.on.doc") { }
                EnhancementButton(title: "Upload", systemIcon: "square.and.arrow.up") { }
                EnhancementButton(title: "Signature", systemIcon: "signature") {
                    showSignatureView = true
                }
            }
            .padding(.horizontal)
        }
    }
}

private struct EnhancementButton: View {
    let title: String
    let systemIcon: String
    var action: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            Button(action: action) {
                VStack {
                    Image(systemName: systemIcon)
                        .font(.system(size: 22))
                        .foregroundColor(.blue)
                }
                .frame(width: 80, height: 60)
                .background(Color.white.opacity(0.9))
                .cornerRadius(14)
                .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
            }
            Text(title)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.black.opacity(0.8))
        }
    }
}
