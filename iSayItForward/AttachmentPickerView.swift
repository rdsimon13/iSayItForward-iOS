import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct AttachmentPickerView: View {
    @Binding var attachments: [MessageAttachment]
    @State private var showingImagePicker = false
    @State private var showingDocumentPicker = false
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Attachments")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Menu {
                    Button {
                        showingImagePicker = true
                    } label: {
                        Label("Add Photos", systemImage: "photo")
                    }
                    
                    Button {
                        showingDocumentPicker = true
                    } label: {
                        Label("Add Documents", systemImage: "doc")
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            
            // Attachment List
            if attachments.isEmpty {
                EmptyAttachmentView()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(attachments) { attachment in
                        AttachmentRowView(
                            attachment: attachment,
                            onRemove: {
                                removeAttachment(attachment)
                            }
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .photosPicker(
            isPresented: $showingImagePicker,
            selection: $selectedPhotoItems,
            maxSelectionCount: 5,
            matching: .images
        )
        .fileImporter(
            isPresented: $showingDocumentPicker,
            allowedContentTypes: [.pdf, .plainText, .rtf, .item],
            allowsMultipleSelection: true
        ) { result in
            handleDocumentSelection(result)
        }
        .onChange(of: selectedPhotoItems) { _ in
            handlePhotoSelection()
        }
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private func EmptyAttachmentView() -> some View {
        VStack(spacing: 12) {
            Image(systemName: "paperclip.circle")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text("No attachments")
                .font(.caption)
                .foregroundColor(.gray)
            
            Text("Tap + to add photos or documents")
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    // MARK: - Attachment Handling
    
    private func removeAttachment(_ attachment: MessageAttachment) {
        attachments.removeAll { $0.id == attachment.id }
    }
    
    private func handlePhotoSelection() {
        Task {
            for item in selectedPhotoItems {
                if let imageData = try? await item.loadTransferable(type: Data.self) {
                    let fileName = "image_\(Date().timeIntervalSince1970).jpg"
                    let attachment = MessageAttachment(
                        data: imageData,
                        fileName: fileName,
                        fileType: .image
                    )
                    
                    await MainActor.run {
                        attachments.append(attachment)
                    }
                }
            }
            
            await MainActor.run {
                selectedPhotoItems = []
            }
        }
    }
    
    private func handleDocumentSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            for url in urls {
                do {
                    let data = try Data(contentsOf: url)
                    let fileName = url.lastPathComponent
                    let attachment = MessageAttachment(
                        data: data,
                        fileName: fileName,
                        fileType: .document
                    )
                    attachments.append(attachment)
                } catch {
                    print("Error loading document: \(error)")
                }
            }
        case .failure(let error):
            print("Document picker error: \(error)")
        }
    }
}

// MARK: - Attachment Row View

struct AttachmentRowView: View {
    let attachment: MessageAttachment
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // File type icon
            Image(systemName: attachment.fileType.systemImageName)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            
            // File info
            VStack(alignment: .leading, spacing: 2) {
                Text(attachment.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(attachment.fileSizeString)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Preview or remove button
            HStack(spacing: 8) {
                if attachment.fileType == .image {
                    AttachmentPreviewView(attachment: attachment)
                }
                
                Button {
                    onRemove()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Attachment Preview

struct AttachmentPreviewView: View {
    let attachment: MessageAttachment
    
    var body: some View {
        Group {
            if attachment.fileType == .image, let uiImage = UIImage(data: attachment.data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: attachment.fileType.systemImageName)
                            .foregroundColor(.gray)
                    )
            }
        }
    }
}

// MARK: - Preview

struct AttachmentPickerView_Previews: PreviewProvider {
    static var previews: some View {
        AttachmentPickerView(attachments: .constant([]))
            .padding()
    }
}