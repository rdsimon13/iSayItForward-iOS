
import SwiftUI
import UniformTypeIdentifiers

struct DocumentUploadView: View {
    @Binding var selectedDocument: URL?
    @Binding var contentAttachments: [ContentAttachment]
    
    @State private var showingDocumentPicker = false
    @State private var dragOver = false

    var body: some View {
        VStack(spacing: 16) {
            if !contentAttachments.filter({ $0.contentType == .document }).isEmpty {
                // Show selected documents
                VStack(alignment: .leading, spacing: 8) {
                    Text("Selected Documents")
                        .font(.headline)
                        .foregroundColor(.teal)
                    
                    ForEach(contentAttachments.filter { $0.contentType == .document }) { attachment in
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundColor(.teal)
                            
                            VStack(alignment: .leading) {
                                Text(attachment.fileName)
                                    .font(.subheadline)
                                    .lineLimit(1)
                                Text(ByteFormatter.format(bytes: attachment.fileSize))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            Button("Remove") {
                                removeAttachment(attachment)
                            }
                            .font(.caption)
                            .foregroundColor(.red)
                        }
                        .padding(.vertical, 4)
                    }
                }
            } else {
                // Upload interface
                RoundedRectangle(cornerRadius: 12)
                    .fill(dragOver ? Color.teal.opacity(0.3) : Color.gray.opacity(0.1))
                    .frame(height: 100)
                    .overlay(
                        VStack {
                            Image(systemName: "doc.text.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 40)
                                .foregroundColor(.teal.opacity(0.7))
                            
                            Text("Tap to select documents")
                                .foregroundColor(.teal)
                                .font(.subheadline)
                            
                            Text("PDF, DOC, DOCX, Pages")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    )
                    .onTapGesture {
                        showingDocumentPicker = true
                    }
                    .onDrop(of: [.fileURL], isTargeted: $dragOver) { providers in
                        handleDroppedDocuments(providers)
                    }
            }
            
            Button("Add Document") {
                showingDocumentPicker = true
            }
            .font(.caption)
            .foregroundColor(.teal)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(14)
        .shadow(radius: 4)
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPicker { url in
                processSelectedDocument(url)
            }
        }
    }
    
    private func processSelectedDocument(_ url: URL) {
        selectedDocument = url
        
        let fileName = url.lastPathComponent
        let fileSize = getFileSize(url: url)
        
        let attachment = ContentAttachment(
            contentType: .document,
            fileName: fileName,
            fileSize: fileSize,
            localURL: url.path,
            metadata: [
                "file_type": (fileName as NSString).pathExtension.lowercased(),
                "source": "document_picker"
            ]
        )
        
        if attachment.isValidSize && attachment.isValidExtension {
            contentAttachments.append(attachment)
        }
    }
    
    private func removeAttachment(_ attachment: ContentAttachment) {
        contentAttachments.removeAll { $0.id == attachment.id }
    }
    
    private func handleDroppedDocuments(_ providers: [NSItemProvider]) -> Bool {
        // Simplified implementation - would handle actual file URLs in real app
        return true
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
