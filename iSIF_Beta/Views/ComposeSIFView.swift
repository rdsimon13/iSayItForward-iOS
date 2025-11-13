import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ComposeSIFView: View {
   
    // MARK: - Initializers
    init(existingSIF: SIF? = nil, isEditing: Bool = false, isResend: Bool = false) {
        self._message = State(initialValue: existingSIF?.message ?? "")
        self._selectedFriends = State(initialValue: existingSIF?.recipients ?? [])
        self.deliveryType = existingSIF?.deliveryType ?? .oneToOne
    }
    // MARK: - State
    @State private var message = ""
    @State private var selectedFriends: [SIFRecipient] = []
    @State private var alertMessage = ""
    @State private var showingAlert = false
    @State private var showConfirmation = false
    @State private var isSending = false
    @State private var sentSIF: SIF?

    var deliveryType: DeliveryType = .oneToOne

    // MARK: - Send Logic
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
                // 🧩 Build SIF object
                let sif = SIF(
                    id: UUID().uuidString,
                    senderUID: uid,
                    recipients: selectedFriends,
                    subject: "My SIF",
                    message: message,
                    deliveryType: deliveryType,
                    scheduledAt: nil,
                    createdAt: Date(),
                    status: "sent"
                )

                print("🚀 Preparing to send SIF to Firestore for user: \(uid)")
                print("📦 SIF payload: \(sif)")

                // 🔥 Write to Firestore
                try await SIFDataManager.shared.saveSIF(sif)
                print("✅ Firestore write completed successfully.")

                // Update UI
                sentSIF = sif
                showConfirmation = true

                // Optional cleanup
                message = ""
                selectedFriends.removeAll()
            } catch {
                alertMessage = "Failed to send SIF: \(error.localizedDescription)"
                showingAlert = true
                print("❌ Firestore send failed: \(error)")
            }
        }
    }

    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextEditor(text: $message)
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(12)
                    .frame(minHeight: 150)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3)))

                Button(action: sendSIF) {
                    if isSending {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("Send SIF")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .background(Color.blue)
                .cornerRadius(12)
                .shadow(radius: 3)
                .disabled(isSending)

                Spacer()
            }
            .padding()
            .navigationTitle("Compose SIF")
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .sheet(isPresented: $showConfirmation) {
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.green)
                    Text("SIF Sent Successfully!")
                        .font(.title2)
                        .bold()
                    Button("Close") {
                        showConfirmation = false
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
    }
}
