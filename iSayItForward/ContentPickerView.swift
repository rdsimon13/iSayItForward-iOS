import SwiftUI
import PhotosUI

struct ContentPickerView: View {
    @Binding var selectedContentType: ContentType
    @Binding var contentAttachments: [ContentAttachment]
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var showingImagePicker = false
    @State private var showingDocumentPicker = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Add Content")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                // Content type selection
                Picker("Content Type", selection: $selectedContentType) {
                    ForEach(ContentType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Content-specific pickers
                VStack(spacing: 16) {
                    switch selectedContentType {
                    case .text:
                        textContentSection
                    case .photo:
                        photoContentSection
                    case .video:
                        videoContentSection
                    case .audio:
                        audioContentSection
                    case .document:
                        documentContentSection
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("Add Content")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    // MARK: - Content Type Sections
    private var textContentSection: some View {
        VStack {
            Text("Text content will be added as the main message")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Button("Add Text File") {
                addSampleAttachment(type: .text, fileName: "text_content.txt")
            }
            .buttonStyle(PrimaryActionButtonStyle())
        }
    }
    
    private var photoContentSection: some View {
        VStack {
            PhotosPicker(
                selection: $selectedItems,
                maxSelectionCount: 5,
                matching: .images,
                photoLibrary: .shared()
            ) {
                VStack {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                    Text("Select Photos")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 120)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
            
            Button("Take Photo") {
                // Placeholder for camera functionality
                addSampleAttachment(type: .photo, fileName: "camera_photo.jpg")
            }
            .buttonStyle(SecondaryActionButtonStyle())
        }
        .onChange(of: selectedItems) { items in
            // Handle selected photos
            for item in items {
                addSampleAttachment(type: .photo, fileName: "selected_photo.jpg")
            }
            selectedItems.removeAll()
        }
    }
    
    private var videoContentSection: some View {
        VStack {
            Button("Select Video") {
                addSampleAttachment(type: .video, fileName: "video.mp4")
            }
            .buttonStyle(PrimaryActionButtonStyle())
            
            Button("Record Video") {
                addSampleAttachment(type: .video, fileName: "recorded_video.mov")
            }
            .buttonStyle(SecondaryActionButtonStyle())
        }
    }
    
    private var audioContentSection: some View {
        VStack {
            Button("Record Audio") {
                addSampleAttachment(type: .audio, fileName: "recording.m4a")
            }
            .buttonStyle(PrimaryActionButtonStyle())
            
            Button("Select Audio File") {
                addSampleAttachment(type: .audio, fileName: "audio_file.mp3")
            }
            .buttonStyle(SecondaryActionButtonStyle())
        }
    }
    
    private var documentContentSection: some View {
        VStack {
            Button("Select Document") {
                showingDocumentPicker = true
            }
            .buttonStyle(PrimaryActionButtonStyle())
            
            Text("Supported formats: PDF, DOC, DOCX, Pages")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPicker { url in
                let fileName = url.lastPathComponent
                let fileSize = getFileSize(url: url)
                addAttachment(type: .document, fileName: fileName, fileSize: fileSize)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func addSampleAttachment(type: ContentType, fileName: String) {
        let attachment = ContentAttachment(
            contentType: type,
            fileName: fileName,
            fileSize: Int.random(in: 1000...1000000),
            metadata: ["source": "content_picker"]
        )
        
        // Validate attachment
        if attachment.isValidSize && attachment.isValidExtension {
            contentAttachments.append(attachment)
        } else {
            alertMessage = "File is too large or has an unsupported format."
            showingAlert = true
        }
    }
    
    private func addAttachment(type: ContentType, fileName: String, fileSize: Int) {
        let attachment = ContentAttachment(
            contentType: type,
            fileName: fileName,
            fileSize: fileSize,
            metadata: ["source": "file_picker"]
        )
        
        if attachment.isValidSize && attachment.isValidExtension {
            contentAttachments.append(attachment)
        } else {
            alertMessage = "File is too large or has an unsupported format."
            showingAlert = true
        }
    }
    
    private func getFileSize(url: URL) -> Int {
        do {
            let resources = try url.resourceValues(forKeys: [.fileSizeKey])
            return resources.fileSize ?? 0
        } catch {
            return 0
        }
    }
}

// MARK: - Document Picker
struct DocumentPicker: UIViewControllerRepresentable {
    let onDocumentPicked: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [
            .pdf, .plainText, .data
        ])
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            parent.onDocumentPicked(url)
        }
    }
}