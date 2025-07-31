import SwiftUI

struct SIFMessagePreviewView: View {
    let sif: SIFItem
    @ObservedObject var viewModel: SIFMessageComposerViewModel
    let onEdit: () -> Void
    let onSend: () -> Void
    
    @State private var showingConfirmation = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.mainAppGradient.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header with preview label
                        previewHeader
                        
                        // Message Preview Card
                        messagePreviewCard
                        
                        // Delivery Information
                        deliveryInfoCard
                        
                        // Privacy and Categories
                        metadataCard
                        
                        // Media Attachments Preview
                        if !sif.mediaAttachments.isEmpty {
                            mediaPreviewCard
                        }
                        
                        // Action Buttons
                        actionButtons
                    }
                    .padding()
                }
            }
            .navigationTitle("Preview SIF")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Edit") {
                        onEdit()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog("Send SIF", isPresented: $showingConfirmation) {
                Button("Send Now") {
                    onSend()
                }
                
                if sif.isScheduled {
                    Button("Schedule for \(sif.scheduledDate.formatted(date: .abbreviated, time: .shortened))") {
                        onSend()
                    }
                }
                
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to send this SIF?")
            }
        }
    }
    
    // MARK: - View Components
    
    private var previewHeader: some View {
        VStack(spacing: 8) {
            Image(systemName: "eye.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(.brandYellow)
            
            Text("Preview Mode")
                .font(.headline)
                .foregroundColor(.brandDarkBlue)
            
            Text("Review your message before sending")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(.white.opacity(0.8))
        .cornerRadius(16)
    }
    
    private var messagePreviewCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Subject
            VStack(alignment: .leading, spacing: 4) {
                Text("Subject")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .textCase(.uppercase)
                
                Text(sif.subject)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.brandDarkBlue)
            }
            
            Divider()
            
            // Message Content
            VStack(alignment: .leading, spacing: 8) {
                Text("Message")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .textCase(.uppercase)
                
                Text(sif.message)
                    .font(.body)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
            }
            
            // Character Count
            HStack {
                Spacer()
                Text("\(sif.characterCount) characters")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }
    
    private var deliveryInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "envelope.circle.fill")
                    .font(.title2)
                    .foregroundColor(.brandYellow)
                
                Text("Delivery Information")
                    .font(.headline)
                    .foregroundColor(.brandDarkBlue)
                
                Spacer()
            }
            
            // Recipients
            VStack(alignment: .leading, spacing: 4) {
                Text("To:")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .textCase(.uppercase)
                
                ForEach(sif.recipients, id: \.self) { recipient in
                    HStack {
                        Image(systemName: "person.circle")
                            .foregroundColor(.brandYellow)
                        Text(recipient)
                            .font(.body)
                    }
                }
            }
            
            Divider()
            
            // Delivery Date
            HStack {
                Image(systemName: sif.isScheduled ? "calendar.circle" : "clock.circle")
                    .foregroundColor(.brandYellow)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(sif.isScheduled ? "Scheduled for:" : "Send immediately")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .textCase(.uppercase)
                    
                    Text(sif.scheduledDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.body)
                        .fontWeight(.medium)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }
    
    private var metadataCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "gear.circle.fill")
                    .font(.title2)
                    .foregroundColor(.brandYellow)
                
                Text("Settings")
                    .font(.headline)
                    .foregroundColor(.brandDarkBlue)
                
                Spacer()
            }
            
            // Privacy Level
            HStack {
                Image(systemName: privacyIcon(for: sif.privacy))
                    .foregroundColor(.brandYellow)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Privacy")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .textCase(.uppercase)
                    
                    Text(sif.privacy.displayName)
                        .font(.body)
                        .fontWeight(.medium)
                }
                
                Spacer()
            }
            
            if !sif.categoryTags.isEmpty {
                Divider()
                
                // Categories
                VStack(alignment: .leading, spacing: 8) {
                    Text("Categories")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .textCase(.uppercase)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                        ForEach(sif.categoryTags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(Color.brandYellow.opacity(0.2))
                                .foregroundColor(.brandDarkBlue)
                                .cornerRadius(12)
                        }
                    }
                }
            }
        }
        .padding()
        .background(.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }
    
    private var mediaPreviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "photo.circle.fill")
                    .font(.title2)
                    .foregroundColor(.brandYellow)
                
                Text("Media Attachments")
                    .font(.headline)
                    .foregroundColor(.brandDarkBlue)
                
                Spacer()
                
                Text("\(sif.mediaAttachments.count)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.brandYellow.opacity(0.2))
                    .cornerRadius(8)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(sif.mediaAttachments) { attachment in
                        attachmentPreview(attachment)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }
    
    private func attachmentPreview(_ attachment: MediaAttachment) -> some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 8)
                .fill(.brandYellow.opacity(0.2))
                .frame(width: 60, height: 60)
                .overlay {
                    Image(systemName: attachment.type == .photo ? "photo" : "video")
                        .font(.title2)
                        .foregroundColor(.brandDarkBlue)
                }
            
            Text(attachment.type.rawValue.capitalized)
                .font(.caption2)
                .foregroundColor(.gray)
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 16) {
            // Send Button
            Button(action: { showingConfirmation = true }) {
                HStack {
                    Image(systemName: "paperplane.fill")
                    Text(sif.isScheduled ? "Schedule SIF" : "Send SIF")
                }
            }
            .buttonStyle(PrimaryActionButtonStyle())
            
            // Edit Button
            Button(action: onEdit) {
                HStack {
                    Image(systemName: "pencil")
                    Text("Edit Message")
                }
            }
            .buttonStyle(SecondaryActionButtonStyle())
        }
    }
    
    // MARK: - Helper Methods
    
    private func privacyIcon(for level: MessageDraft.PrivacyLevel) -> String {
        switch level {
        case .public: return "globe"
        case .friends: return "person.2"
        case .private: return "lock"
        }
    }
}

#Preview {
    let sampleSIF = SIFItem(
        authorUid: "sample",
        recipients: ["john@example.com", "jane@example.com"],
        subject: "Sample SIF Message",
        message: "This is a sample SIF message for preview purposes. It demonstrates how the message will look when sent.",
        createdDate: Date(),
        scheduledDate: Date().addingTimeInterval(3600),
        categoryTags: ["Encouragement", "Friendship"],
        privacyLevel: "friends"
    )
    
    SIFMessagePreviewView(
        sif: sampleSIF,
        viewModel: SIFMessageComposerViewModel(),
        onEdit: {},
        onSend: {}
    )
}