import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ComposeSIFView: View {
    // MARK: - State
    @State private var message = ""
    @State private var selectedFriends: [SIFRecipient] = []
    @State private var alertMessage = ""
    @State private var showingAlert = false
    @State private var showConfirmation = false
    @State private var isSending = false
    @State private var sentSIF: SIF?

    // MARK: - Properties
    var deliveryType: DeliveryType = .oneToOne
    var existingSIF: SIF?
    var isEditing: Bool
    var isResend: Bool

    // MARK: - Init
    init(existingSIF: SIF? = nil, isEditing: Bool = false, isResend: Bool = false) {
        self.existingSIF = existingSIF
        self.isEditing = isEditing
        self.isResend = isResend

        // Prefill message and recipients for edit/resend
        if let existing = existingSIF {
            _message = State(initialValue: existing.message)
            _selectedFriends = State(initialValue: existing.recipients)
        }
    }

    // MARK: - Send
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

        guard let uid = Auth.auth().currentUser?.uid else {
            alertMessage = "You must be logged in to send a SIF."
            showingAlert = true
            return
        }

        Task {
            isSending = true
            defer { isSending = false }

            do {
                // Build new or updated SIF object
                let sif = SIF(
                    id: existingSIF?.id ?? UUID().uuidString,
                    senderUID: uid,
                    recipients: selectedFriends,
                    subject: existingSIF?.subject ?? "My SIF",
                    message: message,
                    deliveryType: deliveryType,
                    scheduledAt: nil,
                    createdAt: existingSIF?.createdAt ?? Date(),
                    status: isEditing ? "edited" : "sent"
                )

                print("🚀 Sending SIF for user: \(uid)")
                print("📦 Payload: \(sif)")

                try await SIFDataManager.shared.sendSIF(sif, for: uid)

                print("✅ SIF successfully written to Firestore")

                sentSIF = sif
                showConfirmation = true

            } catch {
                alertMessage = "Failed to send SIF: \(error.localizedDescription)"
                showingAlert = true
                print("❌ Firestore send failed: \(error)")
            }
        }
    }

    // MARK: - View Body
    var body: some View {
        VStack(spacing: 20) {
            Text(isEditing ? "Edit Your SIF" : isResend ? "Re-Send This SIF" : "Compose a New SIF")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top)

            TextField("Write your message...", text: $message, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
                .frame(minHeight: 100)

            Button(action: sendSIF) {
                if isSending {
                    ProgressView()
                } else {
                    Text(isEditing ? "Save Changes" : isResend ? "Re-Send SIF" : "Send SIF")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .disabled(isSending)
            .padding(.horizontal)

            Spacer()
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showConfirmation) {
            if let sent = sentSIF {
                SIFConfirmationView(sif: sent)
            } else {
                Text("SIF Sent Successfully!")
            }
        }
        .padding(.bottom)
    }
}
