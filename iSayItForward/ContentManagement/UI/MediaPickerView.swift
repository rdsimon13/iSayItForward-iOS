import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

/// View for selecting different types of media content
struct MediaPickerView: View {
    @Binding var selectedContent: [ContentItem]
    @State private var showingPhotoPicker = false
    @State private var showingDocumentPicker = false
    @State private var showingCamera = false
    @State private var showingVideoCamera = false
    @State private var showingAudioRecorder = false
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    
    @StateObject private var contentManager = ContentManager.shared
    
    let allowedTypes: [MediaType]
    let maxSelections: Int
    
    init(selectedContent: Binding<[ContentItem]>, allowedTypes: [MediaType] = MediaType.allCases, maxSelections: Int = 5) {
        self._selectedContent = selectedContent
        self.allowedTypes = allowedTypes
        self.maxSelections = maxSelections
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Add Content")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if !selectedContent.isEmpty {
                    Text("\(selectedContent.count)/\(maxSelections)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Media type selection buttons
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                if allowedTypes.contains(.photo) {
                    MediaTypeButton(
                        title: "Photos",
                        icon: "photo.on.rectangle",
                        color: .blue
                    ) {
                        showingPhotoPicker = true
                    }
                }
                
                if allowedTypes.contains(.photo) {
                    MediaTypeButton(
                        title: "Camera",
                        icon: "camera.fill",
                        color: .green
                    ) {
                        showingCamera = true
                    }
                }
                
                if allowedTypes.contains(.video) {
                    MediaTypeButton(
                        title: "Video",
                        icon: "video.fill",
                        color: .purple
                    ) {
                        showingVideoCamera = true
                    }
                }
                
                if allowedTypes.contains(.audio) {
                    MediaTypeButton(
                        title: "Voice",
                        icon: "mic.circle.fill",
                        color: .red
                    ) {
                        showingAudioRecorder = true
                    }
                }
                
                if allowedTypes.contains(.document) {
                    MediaTypeButton(
                        title: "Files",
                        icon: "folder.fill",
                        color: .orange
                    ) {
                        showingDocumentPicker = true
                    }
                }
                
                if allowedTypes.contains(.text) {
                    MediaTypeButton(
                        title: "Text",
                        icon: "text.alignleft",
                        color: .gray
                    ) {
                        // Add text content functionality
                    }
                }
            }
            
            // Selected content preview
            if !selectedContent.isEmpty {
                SelectedContentView(selectedContent: $selectedContent)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .photosPicker(
            isPresented: $showingPhotoPicker,
            selection: $selectedPhotoItems,
            maxSelectionCount: maxSelections - selectedContent.count,
            matching: .images
        )
        .sheet(isPresented: $showingCamera) {
            PhotoCaptureView { image in
                Task {
                    await addImageToSelection(image)
                }
            }
        }
        .sheet(isPresented: $showingVideoCamera) {
            VideoCaptureView { url in
                Task {
                    await addVideoToSelection(url)
                }
            }
        }
        .sheet(isPresented: $showingAudioRecorder) {
            AudioRecorderView { url in
                Task {
                    await addAudioToSelection(url)
                }
            }
        }
        .fileImporter(
            isPresented: $showingDocumentPicker,
            allowedContentTypes: [.pdf, .plainText, .data],
            allowsMultipleSelection: true
        ) { result in
            Task {
                await handleDocumentSelection(result)
            }
        }
        .onChange(of: selectedPhotoItems) { newItems in
            Task {
                await handlePhotoSelection(newItems)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func addImageToSelection(_ image: UIImage) async {
        guard selectedContent.count < maxSelections else { return }
        
        do {
            // Save image to temp file
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("jpg")
            
            if let imageData = image.jpegData(compressionQuality: 0.9) {
                try imageData.write(to: tempURL)
                let contentItem = try await contentManager.createContentItem(from: tempURL)
                selectedContent.append(contentItem)
            }
        } catch {
            print("Failed to add image: \(error)")
        }
    }
    
    private func addVideoToSelection(_ url: URL) async {
        guard selectedContent.count < maxSelections else { return }
        
        do {
            let contentItem = try await contentManager.createContentItem(from: url)
            selectedContent.append(contentItem)
        } catch {
            print("Failed to add video: \(error)")
        }
    }
    
    private func addAudioToSelection(_ url: URL) async {
        guard selectedContent.count < maxSelections else { return }
        
        do {
            let contentItem = try await contentManager.createContentItem(from: url)
            selectedContent.append(contentItem)
        } catch {
            print("Failed to add audio: \(error)")
        }
    }
    
    private func handlePhotoSelection(_ items: [PhotosPickerItem]) async {
        for item in items {
            guard selectedContent.count < maxSelections else { break }
            
            if let data = try? await item.loadTransferable(type: Data.self) {
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString)
                    .appendingPathExtension("jpg")
                
                do {
                    try data.write(to: tempURL)
                    let contentItem = try await contentManager.createContentItem(from: tempURL)
                    selectedContent.append(contentItem)
                } catch {
                    print("Failed to process photo: \(error)")
                }
            }
        }
        
        selectedPhotoItems.removeAll()
    }
    
    private func handleDocumentSelection(_ result: Result<[URL], Error>) async {
        switch result {
        case .success(let urls):
            for url in urls {
                guard selectedContent.count < maxSelections else { break }
                
                do {
                    let contentItem = try await contentManager.createContentItem(from: url)
                    selectedContent.append(contentItem)
                } catch {
                    print("Failed to add document: \(error)")
                }
            }
        case .failure(let error):
            print("Document selection failed: \(error)")
        }
    }
}

// MARK: - Supporting Views

struct MediaTypeButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

struct SelectedContentView: View {
    @Binding var selectedContent: [ContentItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Selected Content")
                .font(.subheadline)
                .fontWeight(.medium)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(selectedContent) { item in
                        SelectedContentCard(
                            item: item,
                            onRemove: {
                                selectedContent.removeAll { $0.id == item.id }
                            }
                        )
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }
}

struct SelectedContentCard: View {
    let item: ContentItem
    let onRemove: () -> Void
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: item.mediaType.iconName)
                            .font(.title3)
                            .foregroundColor(.secondary)
                    )
                
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                        .background(Color.white)
                        .clipShape(Circle())
                }
                .offset(x: 8, y: -8)
            }
            
            Text(item.displayName)
                .font(.caption2)
                .lineLimit(1)
                .frame(width: 60)
                .truncationMode(.middle)
        }
    }
}