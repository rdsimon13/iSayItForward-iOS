import SwiftUI
import PhotosUI

struct SIFMessageComposerView: View {
    @StateObject private var viewModel = SIFMessageComposerViewModel()
    @State private var showingPreview = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.mainAppGradient.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Recipients Section
                        recipientsSection
                        
                        // Subject Section
                        subjectSection
                        
                        // Message Content Section
                        messageContentSection
                        
                        // Media Attachments Section
                        mediaAttachmentsSection
                        
                        // Category Tags Section
                        categoryTagsSection
                        
                        // Privacy Settings Section
                        privacySettingsSection
                        
                        // Scheduling Section
                        schedulingSection
                        
                        // Action Buttons
                        actionButtonsSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Compose SIF")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Preview") {
                        showingPreview = true
                    }
                    .disabled(!viewModel.isValidMessage)
                }
            }
            .sheet(isPresented: $showingPreview) {
                if let previewSIF = viewModel.createPreviewSIF() {
                    SIFMessagePreviewView(
                        sif: previewSIF,
                        viewModel: viewModel,
                        onEdit: { showingPreview = false },
                        onSend: { 
                            showingPreview = false
                            sendMessage()
                        }
                    )
                }
            }
            .photosPicker(
                isPresented: $viewModel.showingImagePicker,
                selection: $viewModel.selectedPhotos,
                maxSelectionCount: viewModel.maxAttachments - viewModel.mediaAttachments.count,
                matching: .images
            )
            .onChange(of: viewModel.selectedPhotos) { _ in
                viewModel.handleSelectedPhotos()
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK") {}
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    // MARK: - View Sections
    
    private var recipientsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("To:")
                    .font(.headline)
                    .foregroundColor(.brandDarkBlue)
                Spacer()
                Text("Required")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            TextField("Enter email addresses (comma separated)", text: $viewModel.recipients)
                .textFieldStyle(PillTextFieldStyle())
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
        }
    }
    
    private var subjectSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Subject:")
                    .font(.headline)
                    .foregroundColor(.brandDarkBlue)
                Spacer()
                Text("Required")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            TextField("Enter subject", text: $viewModel.subject)
                .textFieldStyle(PillTextFieldStyle())
        }
    }
    
    private var messageContentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Message:")
                    .font(.headline)
                    .foregroundColor(.brandDarkBlue)
                Spacer()
                Text("\(viewModel.characterCount)/\(viewModel.maxCharacterLimit)")
                    .font(.caption)
                    .foregroundColor(viewModel.characterCount > viewModel.maxCharacterLimit ? .red : .gray)
            }
            
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.white.opacity(0.8))
                    .frame(minHeight: 120)
                
                if viewModel.message.isEmpty {
                    Text("Share your message with the world...")
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                        .padding(.leading, 16)
                }
                
                TextEditor(text: $viewModel.message)
                    .padding(8)
                    .background(Color.clear)
                    .scrollContentBackground(.hidden)
            }
            
            if !viewModel.validationErrors.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(viewModel.validationErrors, id: \.self) { error in
                        Text("• \(error)")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var mediaAttachmentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Media:")
                    .font(.headline)
                    .foregroundColor(.brandDarkBlue)
                Spacer()
                Text("\(viewModel.mediaAttachments.count)/\(viewModel.maxAttachments)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Add Photo Button
                    Button(action: { viewModel.addPhotoAttachment() }) {
                        VStack {
                            Image(systemName: "photo.badge.plus")
                                .font(.title2)
                            Text("Photo")
                                .font(.caption)
                        }
                        .foregroundColor(.brandDarkBlue)
                        .frame(width: 80, height: 80)
                        .background(.white.opacity(0.8))
                        .cornerRadius(12)
                    }
                    .disabled(viewModel.mediaAttachments.count >= viewModel.maxAttachments)
                    
                    // Media Attachments
                    ForEach(viewModel.mediaAttachments) { attachment in
                        mediaAttachmentView(attachment)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func mediaAttachmentView(_ attachment: MediaAttachment) -> some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.8))
                .frame(width: 80, height: 80)
                .overlay {
                    if attachment.type == .photo {
                        Image(systemName: "photo")
                            .font(.title2)
                            .foregroundColor(.brandDarkBlue)
                    } else {
                        Image(systemName: "video")
                            .font(.title2)
                            .foregroundColor(.brandDarkBlue)
                    }
                }
            
            Button(action: { viewModel.removeAttachment(attachment) }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .background(.white)
                    .clipShape(Circle())
            }
            .offset(x: 8, y: -8)
        }
    }
    
    private var categoryTagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Categories:")
                .font(.headline)
                .foregroundColor(.brandDarkBlue)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 8) {
                ForEach(viewModel.availableTags, id: \.self) { tag in
                    Button(action: { viewModel.toggleTag(tag) }) {
                        Text(tag)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(viewModel.isTagSelected(tag) ? Color.brandYellow : .white.opacity(0.8))
                            .foregroundColor(viewModel.isTagSelected(tag) ? .white : .brandDarkBlue)
                            .cornerRadius(16)
                    }
                }
            }
        }
    }
    
    private var privacySettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Privacy:")
                .font(.headline)
                .foregroundColor(.brandDarkBlue)
            
            Picker("Privacy Level", selection: $viewModel.privacyLevel) {
                ForEach(MessageDraft.PrivacyLevel.allCases, id: \.self) { level in
                    HStack {
                        Image(systemName: privacyIcon(for: level))
                        Text(level.displayName)
                    }
                    .tag(level)
                }
            }
            .pickerStyle(.segmented)
            .background(.white.opacity(0.3))
            .cornerRadius(8)
        }
    }
    
    private var schedulingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Schedule for later", isOn: $viewModel.shouldSchedule)
                .tint(Color.brandYellow)
                .padding()
                .background(.white.opacity(0.2))
                .cornerRadius(16)
            
            if viewModel.shouldSchedule {
                DatePicker(
                    "Delivery Date & Time",
                    selection: $viewModel.scheduledDate,
                    in: Date()...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.compact)
                .padding()
                .background(.white.opacity(0.85))
                .cornerRadius(16)
            }
        }
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            // Draft Status
            if viewModel.isDraft {
                HStack {
                    Image(systemName: "doc.text.below.ecg")
                        .foregroundColor(.gray)
                    Text("Auto-saved as draft")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            HStack(spacing: 16) {
                // Save Draft Button
                Button("Save Draft") {
                    viewModel.saveDraft()
                }
                .buttonStyle(SecondaryActionButtonStyle())
                
                // Send Button
                Button("Send SIF") {
                    sendMessage()
                }
                .buttonStyle(PrimaryActionButtonStyle())
                .disabled(!viewModel.isValidMessage)
            }
            
            // Clear All Button
            Button("Clear All") {
                viewModel.clearAll()
            }
            .foregroundColor(.red)
            .padding(.top, 8)
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
    
    private func sendMessage() {
        Task {
            do {
                let messageId = try await viewModel.sendMessage()
                await MainActor.run {
                    alertMessage = "Your SIF has been sent successfully!"
                    showingAlert = true
                }
            } catch {
                await MainActor.run {
                    alertMessage = "Failed to send SIF: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
}

#Preview {
    SIFMessageComposerView()
}