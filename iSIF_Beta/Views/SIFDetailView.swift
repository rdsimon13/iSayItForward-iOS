import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import MessageUI
import Foundation

struct SIFDetailView: View {
    @EnvironmentObject var router: TabRouter
    @EnvironmentObject var authState: AuthState

    let sif: SIF
    @State private var showDeleteAlert = false
    @State private var isDeleting = false
    @State private var showToast = false
    @State private var showMailComposer = false
    @State private var mailData = MailData(subject: "", recipients: [], message: "")
    @State private var alertMessage = ""
    @State private var showingAlert = false

    var body: some View {
        ZStack {
            GradientTheme.welcomeBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 25) {
                    headerSection
                    messageCard
                    sifMetadata
                    actionButtons
                }
                .padding(.horizontal, 20)
                .padding(.top, 40)
                .padding(.bottom, 120)
            }

            BottomNavBar(
                selectedTab: $router.selectedTab,
                isVisible: .constant(true)
            )
            .environmentObject(router)

            if showToast { toastView }
        }
        .navigationBarBackButtonHidden(true)
        .alert("Delete SIF?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive, action: deleteSIF)
        } message: {
            Text("Are you sure you want to permanently delete this SIF?")
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showMailComposer) {
            MailView(data: $mailData)
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        let subjectText = sif.subject ?? ""
        return VStack(spacing: 8) {
            Text(subjectText.isEmpty ? "SIF Message" : subjectText)
                .font(.custom("AvenirNext-DemiBold", size: 26))
                .foregroundColor(Color(hex: "132E37"))

            Text("Created on \(sif.createdAt.formatted(date: .abbreviated, time: .shortened))")
                .font(.custom("AvenirNext-Regular", size: 14))
                .foregroundColor(.gray)
        }
        .padding(.top, 20)
    }

    // MARK: - Message Card
    private var messageCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Message")
                .font(.custom("AvenirNext-DemiBold", size: 16))
                .foregroundColor(.gray)

            Text(sif.message)
                .font(.custom("AvenirNext-Regular", size: 16))
                .foregroundColor(.black.opacity(0.9))
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.9))
                        .shadow(color: .black.opacity(0.1), radius: 4, y: 3)
                )
        }
    }

    // MARK: - Metadata
    private var sifMetadata: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Details")
                .font(.custom("AvenirNext-DemiBold", size: 18))
                .foregroundColor(.black.opacity(0.8))

            Divider()

            metaRow(label: "Recipient", value: sif.recipients.first?.name ?? "Unknown")
            metaRow(label: "Email", value: sif.recipients.first?.email ?? "N/A")
            metaRow(label: "Tone", value: "—")
            metaRow(label: "Emotion", value: "—")

            metaRow(label: "Delivery Type", value: DeliveryType(rawValue: sif.deliveryType)?.displayTitle ?? sif.deliveryType)

            if let date = sif.deliveryDate {
                metaRow(label: "Scheduled For", value: date.formatted(date: .abbreviated, time: .shortened))
            }
            metaRow(label: "Delivery Channel", value: sif.deliveryChannel)
            if let template = sif.templateName {
                metaRow(label: "Template", value: template)
            }
            if let attachments = sif.attachments, !attachments.isEmpty {
                metaRow(label: "Attachments", value: "\(attachments.count) file(s)")
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.95))
                .shadow(color: .black.opacity(0.1), radius: 5, y: 3)
        )
    }

    private func metaRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.custom("AvenirNext-Regular", size: 15))
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.custom("AvenirNext-DemiBold", size: 15))
                .foregroundColor(Color(hex: "132E37"))
        }
    }

    // MARK: - Buttons
    private var actionButtons: some View {
        VStack(spacing: 15) {
            NavigationLink(destination: ComposeSIFView()) {
                actionButton(title: "✏️ Edit SIF", color: .orange)
            }

            NavigationLink(destination: ComposeSIFView(existingSIF: sif, isEditing: false, isResend: true)) {
                actionButton(title: "📤 Re-Send SIF", color: .blue)
            }

            ShareLink(
                item: buildShareMessage(),
                preview: SharePreview("Share SIF", image: Image(systemName: "paperplane.fill"))
            ) {
                actionButton(title: "🌍 Share Externally", color: .purple)
            }

            Button {
                prepareMailData()
                showMailComposer = true
            } label: {
                actionButton(title: "📧 Send via Email", color: .teal)
            }

            Button(role: .destructive) {
                showDeleteAlert = true
            } label: {
                actionButton(title: isDeleting ? "Deleting..." : "🗑️ Delete SIF", color: .red)
            }
            .disabled(isDeleting)
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

    // MARK: - Share + Mail Logic
    private func buildShareMessage() -> String {
        let senderName = Auth.auth().currentUser?.displayName ?? "An iSayItForward user"
        let subjectText = sif.subject ?? "SIF Message"
        return """
        💌 iSayItForward SIF Message 💌

        From: \(senderName)
        To: \(sif.recipients.first?.name ?? "Someone Special")

        “\(sif.message)”

        Tone: —
        Emotion: —
        Delivery: \(sif.deliveryType.displayTitle)

        Subject: \(subjectText)
        ✨ Sent via iSayItForward — where kindness travels through time.
        """
    }

    private func prepareMailData() {
        let subjectText = sif.subject ?? "iSIF Message"
        let body = buildShareMessage()
        let recipients = [sif.recipients.first?.email ?? ""].filter { !$0.isEmpty }
        mailData = MailData(subject: subjectText, recipients: recipients, message: body)
    }

    // MARK: - Toast View
    private var toastView: some View {
        VStack {
            Spacer()
            Text("✅ SIF Deleted Successfully!")
                .font(.custom("AvenirNext-DemiBold", size: 15))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Capsule().fill(Color.green.opacity(0.9)))
                .shadow(radius: 3)
                .padding(.bottom, 80)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Delete Logic
    private func deleteSIF() {
        Task {
            do {
                isDeleting = true
                let db = Firestore.firestore()
                try await db.collection("SIFs").document(sif.id).delete()

                isDeleting = false
                showDeleteAlert = false
                withAnimation { showToast = true }

            } catch {
                isDeleting = false
                showDeleteAlert = false
                alertMessage = "Failed to delete SIF: \(error.localizedDescription)"
                showingAlert = true
            }
        }
    }
}

// MARK: - Mail Support
struct MailData {
    var subject: String
    var recipients: [String]
    var message: String
}

struct MailView: UIViewControllerRepresentable {
    @Binding var data: MailData
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        if MFMailComposeViewController.canSendMail() {
            vc.setSubject(data.subject)
            vc.setToRecipients(data.recipients)
            vc.setMessageBody(data.message, isHTML: false)
            vc.mailComposeDelegate = context.coordinator
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        var parent: MailView
        init(parent: MailView) { self.parent = parent }

        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            parent.dismiss()
        }
    }
}
