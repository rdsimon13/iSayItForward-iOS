import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ComposeSIFView: View {
    // MARK: - Dependencies
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authState: AuthState
    @EnvironmentObject var router: TabRouter

    // MARK: - Passed Values
    let existingSIF: SIF?
    let isEditing: Bool
    let isResend: Bool

    // MARK: - State
    @State private var message: String = ""
    @State private var selectedFriends: [SIFRecipient] = []
    @State private var alertMessage: String = ""
    @State private var showAlert: Bool = false
    @State private var showConfirmation: Bool = false
    @State private var isSending: Bool = false
    @State private var deliveryType: String = "One-to-One"
    @State private var scheduledAt: Date? = nil

    // MARK: - Init
    init(existingSIF: SIF? = nil, isEditing: Bool = false, isResend: Bool = false) {
        self.existingSIF = existingSIF
        self.isEditing = isEditing
        self.isResend = isResend

        // Use plain strings for compatibility with Firestore
        _message = State(initialValue: existingSIF?.message ?? "")
        _selectedFriends = State(initialValue: existingSIF?.recipients ?? [])
        _deliveryType = State(initialValue: existingSIF?.deliveryType ?? "One-to-One")
        _scheduledAt = State(initialValue: existingSIF?.deliveryDate)
    }

    // MARK: - View Body
    var body: some View {
        ZStack {
            GradientTheme.welcomeBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 25) {
                    headerSection
                    recipientSection
                    messageSection
                    deliveryTypePicker
                    actionButtons
                }
                .padding(.horizontal, 20)
                .padding(.top, 40)
                .padding(.bottom, 100)
            }
        }
        .alert("Error", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .alert("✅ SIF Sent!", isPresented: $showConfirmation) {
            Button("OK", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("Your message has been sent successfully.")
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text(isEditing ? "Edit SIF" : isResend ? "Re-Send SIF" : "Compose New SIF")
                .font(.custom("AvenirNext-DemiBold", size: 26))
                .foregroundColor(Color(hex: "132E37"))

            Text("Send thoughtful messages that travel through time ✨")
                .font(.custom("AvenirNext-Regular", size: 15))
                .foregroundColor(.gray)
        }
    }

    // MARK: - Recipient Section
    private var recipientSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("To:")
                .font(.custom("AvenirNext-DemiBold", size: 16))
                .foregroundColor(.gray)

            if selectedFriends.isEmpty {
                Text("No recipient selected.")
                    .font(.custom("AvenirNext-Regular", size: 14))
                    .foregroundColor(.secondary)
            } else {
                ForEach(selectedFriends, id: \.id) { friend in
                    HStack {
                        Text(friend.name)
                            .font(.custom("AvenirNext-Regular", size: 15))
                        Spacer()
                        Text(friend.email)
                            .font(.custom("AvenirNext-Regular", size: 13))
                            .foregroundColor(.gray)
                    }
                }
            }

            Button(action: {
                // TODO: Show friend picker modal
            }) {
                Label("Select Friend", systemImage: "person.crop.circle.badge.plus")
                    .font(.custom("AvenirNext-DemiBold", size: 15))
                    .padding(10)
                    .frame(maxWidth: .infinity)
                    .background(Capsule().fill(Color.blue.opacity(0.8)))
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.95))
                .shadow(color: .black.opacity(0.1), radius: 5, y: 3)
        )
    }

    // MARK: - Message Section
    private var messageSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Message")
                .font(.custom("AvenirNext-DemiBold", size: 16))
                .foregroundColor(.gray)

            TextEditor(text: $message)
                .frame(height: 150)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 15).fill(Color.white))
                .shadow(color: .black.opacity(0.1), radius: 3, y: 2)
                .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.gray.opacity(0.2)))
        }
    }

    // MARK: - Delivery Type Picker
    private var deliveryTypePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Delivery Type")
                .font(.custom("AvenirNext-DemiBold", size: 16))
                .foregroundColor(.gray)

            Picker("Delivery Type", selection: $deliveryType) {
                Text("One-to-One").tag("One-to-One")
                Text("Scheduled Delivery").tag("Scheduled Delivery")
                Text("Broadcast Message").tag("Broadcast Message")
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.95))
                .shadow(color: .black.opacity(0.1), radius: 5, y: 3)
        )
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 15) {
            Button(action: sendSIF) {
                actionButton(title: isResend ? "📤 Re-Send SIF" : "💌 Send SIF", color: .green)
            }
            .disabled(isSending)

            Button(role: .cancel) {
                dismiss()
            } label: {
                actionButton(title: "❌ Cancel", color: .red)
            }
        }
        .padding(.top, 20)
    }

    private func actionButton(title: String, color: Color) -> some View {
        Text(title)
            .font(.custom("AvenirNext-DemiBold", size: 17))
            .foregroundColor(.white)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                Capsule()
                    .fill(color.opacity(0.9))
                    .shadow(color: color.opacity(0.4), radius: 4, y: 2)
            )
    }

    // MARK: - Send Logic
    private func sendSIF() {
        guard !message.isEmpty else {
            alertMessage = "Please enter a message."
            showAlert = true
            return
        }

        guard let user = Auth.auth().currentUser else {
            alertMessage = "User not authenticated."
            showAlert = true
            return
        }

        guard !selectedFriends.isEmpty else {
            alertMessage = "Please select at least one recipient."
            showAlert = true
            return
        }

        isSending = true

        let newSIF = SIF(
            senderUID: user.uid,
            recipients: selectedFriends,
            subject: nil,
            message: message,
            deliveryType: deliveryType, // ✅ pure String, Firestore-safe
            deliveryDate: scheduledAt,
            createdAt: Date(),
            status: "sent"
        )

        Task {
            do {
                try await SIFDataManager.shared.saveSIF(newSIF)
                isSending = false
                showConfirmation = true
            } catch {
                isSending = false
                alertMessage = "Failed to send SIF: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
}
