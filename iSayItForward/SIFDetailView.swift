import SwiftUI

struct SIFDetailView: View {
    let sif: SIFItem
    @State private var showingContentPreview = false
    @State private var selectedContentItem: ContentItem?

    var body: some View {
        ZStack {
            Color.mainAppGradient.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // Detail Card for Key Information
                    VStack(alignment: .leading, spacing: 12) {
                        DetailRow(icon: "person.2.fill", title: "Recipients", value: sif.recipients.joined(separator: ", "))
                        Divider()
                        DetailRow(icon: "calendar", title: "Scheduled For", value: sif.scheduledDate.formatted(date: .long, time: .shortened))
                        Divider()
                        DetailRow(icon: "paperplane.fill", title: "Subject", value: sif.subject)
                    }
                    .padding()
                    .background(.white.opacity(0.85))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.1), radius: 5, y: 2)

                    // Card for the Message Body
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Message")
                            .font(.headline)
                        
                        Text(sif.message)
                            .font(.body)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white.opacity(0.85))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.1), radius: 5, y: 2)

                    // Attachments section
                    if sif.hasAttachments {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Attachments (\(sif.contentItems.count))")
                                .font(.headline)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                ForEach(sif.contentItems) { contentItem in
                                    AttachmentCard(contentItem: contentItem) {
                                        selectedContentItem = contentItem
                                        showingContentPreview = true
                                    }
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.white.opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("SIF Details")
        }
        .foregroundColor(Color.brandDarkBlue)
        .sheet(isPresented: $showingContentPreview) {
            if let contentItem = selectedContentItem {
                ContentPreviewView(contentItem: contentItem)
            }
        }
    }
}

// Attachment card view
struct AttachmentCard: View {
    let contentItem: ContentItem
    let onTap: () -> Void
    @State private var thumbnail: UIImage?
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
                    .frame(height: 80)
                    .overlay(
                        Group {
                            if let thumbnail = thumbnail {
                                Image(uiImage: thumbnail)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .clipped()
                            } else {
                                VStack(spacing: 4) {
                                    Image(systemName: contentItem.mediaType.iconName)
                                        .font(.title2)
                                        .foregroundColor(iconColor)
                                    
                                    Text(contentItem.mediaType.displayName)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(spacing: 2) {
                    Text(contentItem.displayName)
                        .font(.caption)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    
                    Text(contentItem.formattedFileSize)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
        .onAppear {
            loadThumbnail()
        }
    }
    
    private var iconColor: Color {
        switch contentItem.mediaType {
        case .photo:
            return .blue
        case .video:
            return .purple
        case .audio:
            return .red
        case .document:
            return .orange
        case .text:
            return .gray
        }
    }
    
    private func loadThumbnail() {
        Task {
            thumbnail = await ContentManager.shared.generateThumbnail(for: contentItem)
        }
    }
}

// Helper view for a consistent row style in the detail card
private struct DetailRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.body.weight(.semibold))
        }
    }
}

// Preview requires a sample SIFItem to work
struct SIFDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SIFDetailView(sif: SIFItem(authorUid: "123", recipients: ["preview@example.com"], subject: "Preview Subject", message: "This is a longer preview message to see how the text wraps and the card expands.", createdDate: Date(), scheduledDate: Date()))
        }
    }
}
