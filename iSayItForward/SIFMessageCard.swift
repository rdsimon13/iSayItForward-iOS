import SwiftUI
import FirebaseAuth

// MARK: - SIFMessageCard
struct SIFMessageCard: View {
    let sif: SIFItem
    let onLikeTapped: () -> Void
    let onShareTapped: () -> Void
    let onCardTapped: () -> Void
    
    @State private var showShareSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Card Header
            cardHeader
            
            // Card Content
            cardContent
            
            // Attachment Preview (if available)
            if let attachmentURL = sif.attachmentURL, !attachmentURL.isEmpty {
                attachmentPreview
            }
            
            // Card Actions
            cardActions
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
        .overlay(
            // Read/Unread indicator
            RoundedRectangle(cornerRadius: 16)
                .stroke(isRead ? Color.clear : Color.brandYellow, lineWidth: 2)
        )
        .onTapGesture {
            onCardTapped()
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [createShareText()])
        }
    }
    
    // MARK: - Card Components
    
    private var cardHeader: some View {
        HStack(spacing: 12) {
            // Profile Avatar
            Circle()
                .fill(Color.brandDarkBlue.opacity(0.1))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(senderInitials)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.brandDarkBlue)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                // Sender name (placeholder - would come from user lookup)
                Text("SIF Sender")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.brandDarkBlue)
                
                // Timestamp
                Text(formatTimestamp(sif.createdDate))
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Template indicator
            if let templateName = sif.templateName {
                Text(templateName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.brandYellow.opacity(0.2))
                    .foregroundColor(.brandDarkBlue)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
    
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Subject
            if !sif.subject.isEmpty {
                Text(sif.subject)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.brandDarkBlue)
                    .lineLimit(2)
            }
            
            // Message content
            Text(sif.message)
                .font(.system(size: 16))
                .foregroundColor(.primary)
                .lineLimit(4)
                .multilineTextAlignment(.leading)
            
            // Recipients preview
            if !sif.recipients.isEmpty {
                HStack {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    
                    Text("To: \(recipientsText)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    
    private var attachmentPreview: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.gray.opacity(0.1))
            .frame(height: 120)
            .overlay(
                VStack(spacing: 8) {
                    Image(systemName: "doc.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.brandDarkBlue)
                    
                    Text("Attachment")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            )
            .padding(.horizontal, 16)
            .padding(.top, 8)
    }
    
    private var cardActions: some View {
        HStack(spacing: 24) {
            // Like button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    onLikeTapped()
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .foregroundColor(isLiked ? .red : .secondary)
                        .scaleEffect(isLiked ? 1.1 : 1.0)
                    
                    if sif.likes.count > 0 {
                        Text("\(sif.likes.count)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Share button
            Button(action: {
                onShareTapped()
                showShareSheet = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.secondary)
                    
                    Text("Share")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Scheduled date indicator
            if sif.scheduledDate > Date() {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .foregroundColor(.brandYellow)
                        .font(.caption)
                    
                    Text("Scheduled")
                        .font(.caption)
                        .foregroundColor(.brandYellow)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Helper Properties
    
    private var isLiked: Bool {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return false }
        return sif.likes.contains(currentUserId)
    }
    
    private var isRead: Bool {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return true }
        return sif.readBy.contains(currentUserId)
    }
    
    private var senderInitials: String {
        // This would ideally come from a user lookup based on authorUid
        // For now, using first character of authorUid or a default
        return String(sif.authorUid.prefix(1)).uppercased().isEmpty ? "U" : String(sif.authorUid.prefix(1)).uppercased()
    }
    
    private var recipientsText: String {
        if sif.recipients.count <= 2 {
            return sif.recipients.joined(separator: ", ")
        } else {
            return "\(sif.recipients.prefix(2).joined(separator: ", ")) +\(sif.recipients.count - 2) more"
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func createShareText() -> String {
        let subject = sif.subject.isEmpty ? "SIF Message" : sif.subject
        return "\(subject)\n\n\(sif.message)\n\nShared from iSayItForward"
    }
}

// MARK: - ShareSheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview
struct SIFMessageCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            SIFMessageCard(
                sif: SIFItem(
                    authorUid: "user123",
                    recipients: ["john@example.com", "jane@example.com"],
                    subject: "Happy Birthday!",
                    message: "Wishing you a wonderful birthday filled with joy, laughter, and all your favorite things. Hope your special day is everything you dreamed it would be!",
                    createdDate: Date().addingTimeInterval(-3600),
                    scheduledDate: Date().addingTimeInterval(86400),
                    attachmentURL: nil,
                    templateName: "Birthday",
                    likes: ["user1", "user2", "user3"],
                    readBy: ["user1"]
                ),
                onLikeTapped: { print("Liked") },
                onShareTapped: { print("Shared") },
                onCardTapped: { print("Card tapped") }
            )
            
            SIFMessageCard(
                sif: SIFItem(
                    authorUid: "user456",
                    recipients: ["team@company.com"],
                    subject: "Thank You",
                    message: "Thank you for all your hard work on the project. Your dedication and expertise made all the difference.",
                    createdDate: Date().addingTimeInterval(-7200),
                    scheduledDate: Date(),
                    attachmentURL: "https://example.com/attachment.pdf",
                    templateName: nil,
                    likes: [],
                    readBy: []
                ),
                onLikeTapped: { print("Liked") },
                onShareTapped: { print("Shared") },
                onCardTapped: { print("Card tapped") }
            )
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .previewLayout(.sizeThatFits)
    }
}