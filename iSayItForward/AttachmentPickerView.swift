import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

// MARK: - Attachment Picker View
struct AttachmentPickerView: View {
    @Binding var attachments: [Attachment]
    @StateObject private var attachmentManager = AttachmentManager.shared
    
    @State private var showingImagePicker = false
    @State private var showingDocumentPicker = false
    @State private var showingCamera = false
    @State private var showingActionSheet = false
    @State private var showingPhotoPicker = false
    
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var isProcessing = false
    @State private var processingProgress: Double = 0
    
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Attachments")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: { showingActionSheet = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.brandYellow)
                }
            }
            
            // Processing indicator
            if isProcessing {
                ProgressView("Processing files...", value: processingProgress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: .brandYellow))
            }
            
            // Attachments grid
            if !attachments.isEmpty {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8)
                ], spacing: 8) {
                    ForEach(attachments) { attachment in
                        AttachmentThumbnailView(
                            attachment: attachment,
                            onDelete: {
                                removeAttachment(attachment)
                            }
                        )
                    }
                }
                .padding(.horizontal, 4)
            } else {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "paperclip")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.6))
                    
                    Text("No attachments")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                    
                    Text("Tap + to add photos, videos, or documents")
                        .foregroundColor(.gray.opacity(0.8))
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 120)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4)
        .confirmationDialog("Add Attachment", isPresented: $showingActionSheet) {
            Button("Camera") {
                showingCamera = true
            }
            
            Button("Photo Library") {
                showingPhotoPicker = true
            }
            
            Button("Documents") {
                showingDocumentPicker = true
            }
            
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Choose the type of file to attach")
        }
        .photosPicker(
            isPresented: $showingPhotoPicker,
            selection: $selectedPhotoItems,
            maxSelectionCount: 5,
            matching: .any(of: [.images, .videos])
        )
        .onChange(of: selectedPhotoItems) { items in
            processPhotoPickerItems(items)
        }
        .sheet(isPresented: $showingCamera) {
            CameraCaptureView { image in
                processCapturedImage(image)
            }
        }
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPickerView { urls in
                processDocumentURLs(urls)
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - File Processing Methods
    private func processPhotoPickerItems(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }
        
        isProcessing = true
        processingProgress = 0
        
        Task {
            let totalItems = Double(items.count)
            
            for (index, item) in items.enumerated() {
                do {
                    if let data = try await item.loadTransferable(type: Data.self) {
                        let tempURL = try createTemporaryFile(from: data, with: item.suggestedName ?? "image.jpg")
                        let attachment = try await attachmentManager.processFile(
                            from: tempURL,
                            originalName: item.suggestedName ?? "image.jpg"
                        )
                        
                        await MainActor.run {
                            attachments.append(attachment)
                            processingProgress = Double(index + 1) / totalItems
                        }
                        
                        // Clean up temp file
                        try FileManager.default.removeItem(at: tempURL)
                    }
                } catch {
                    await MainActor.run {
                        showError(error.localizedDescription)
                    }
                }
            }
            
            await MainActor.run {
                isProcessing = false
                selectedPhotoItems = []
            }
        }
    }
    
    private func processCapturedImage(_ image: UIImage) {
        isProcessing = true
        
        Task {
            do {
                let imageData = image.jpegData(compressionQuality: 0.8) ?? Data()
                let tempURL = try createTemporaryFile(from: imageData, with: "captured_image.jpg")
                let attachment = try await attachmentManager.processFile(
                    from: tempURL,
                    originalName: "captured_image.jpg"
                )
                
                await MainActor.run {
                    attachments.append(attachment)
                    isProcessing = false
                }
                
                // Clean up temp file
                try FileManager.default.removeItem(at: tempURL)
            } catch {
                await MainActor.run {
                    showError(error.localizedDescription)
                    isProcessing = false
                }
            }
        }
    }
    
    private func processDocumentURLs(_ urls: [URL]) {
        guard !urls.isEmpty else { return }
        
        isProcessing = true
        processingProgress = 0
        
        Task {
            let totalItems = Double(urls.count)
            
            for (index, url) in urls.enumerated() {
                do {
                    // Access security-scoped resource
                    let accessing = url.startAccessingSecurityScopedResource()
                    defer {
                        if accessing {
                            url.stopAccessingSecurityScopedResource()
                        }
                    }
                    
                    let attachment = try await attachmentManager.processFile(
                        from: url,
                        originalName: url.lastPathComponent
                    )
                    
                    await MainActor.run {
                        attachments.append(attachment)
                        processingProgress = Double(index + 1) / totalItems
                    }
                } catch {
                    await MainActor.run {
                        showError(error.localizedDescription)
                    }
                }
            }
            
            await MainActor.run {
                isProcessing = false
            }
        }
    }
    
    private func createTemporaryFile(from data: Data, with name: String) throws -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
        let tempURL = tempDirectory.appendingPathComponent(name)
        try data.write(to: tempURL)
        return tempURL
    }
    
    private func removeAttachment(_ attachment: Attachment) {
        attachments.removeAll { $0.id == attachment.id }
        
        // Clean up local files
        if let localURL = attachment.localURL {
            try? FileManager.default.removeItem(at: localURL)
        }
        
        if let thumbnailURL = attachmentManager.getThumbnailURL(for: attachment) {
            try? FileManager.default.removeItem(at: thumbnailURL)
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}

// MARK: - Attachment Thumbnail View
struct AttachmentThumbnailView: View {
    let attachment: Attachment
    let onDelete: () -> Void
    
    @StateObject private var attachmentManager = AttachmentManager.shared
    @State private var thumbnailImage: UIImage?
    
    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
                .frame(width: 100, height: 100)
            
            // Content
            VStack(spacing: 4) {
                if let thumbnailImage = thumbnailImage {
                    Image(uiImage: thumbnailImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Image(systemName: attachment.systemImageName)
                        .font(.system(size: 24))
                        .foregroundColor(.brandYellow)
                        .frame(width: 80, height: 60)
                }
                
                Text(attachment.originalName)
                    .font(.caption2)
                    .lineLimit(1)
                    .frame(width: 80)
                
                Text(attachment.displaySize)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            // Delete button
            VStack {
                HStack {
                    Spacer()
                    Button(action: onDelete) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.red)
                            .background(Color.white)
                            .clipShape(Circle())
                    }
                }
                Spacer()
            }
            .padding(4)
        }
        .onAppear {
            loadThumbnail()
        }
    }
    
    private func loadThumbnail() {
        guard attachment.fileType == .image || attachment.fileType == .video else { return }
        
        if let thumbnailURL = attachmentManager.getThumbnailURL(for: attachment) {
            thumbnailImage = UIImage(contentsOfFile: thumbnailURL.path)
        } else if let localURL = attachmentManager.getLocalURL(for: attachment),
                  attachment.fileType == .image {
            thumbnailImage = UIImage(contentsOfFile: localURL.path)
        }
    }
}

// MARK: - Camera Capture View
struct CameraCaptureView: UIViewControllerRepresentable {
    let onImageCaptured: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraCaptureView
        
        init(_ parent: CameraCaptureView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImageCaptured(image)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Document Picker View
struct DocumentPickerView: UIViewControllerRepresentable {
    let onDocumentsSelected: ([URL]) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [
            .pdf, .text, .rtf, .image, .movie, .audio,
            UTType(filenameExtension: "doc")!,
            UTType(filenameExtension: "docx")!,
            UTType(filenameExtension: "xls")!,
            UTType(filenameExtension: "xlsx")!,
            UTType(filenameExtension: "ppt")!,
            UTType(filenameExtension: "pptx")!
        ], allowsMultipleSelection: true)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPickerView
        
        init(_ parent: DocumentPickerView) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            parent.onDocumentsSelected(urls)
            parent.dismiss()
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.dismiss()
        }
    }
}