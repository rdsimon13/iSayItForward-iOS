
import SwiftUI
import UniformTypeIdentifiers

struct DocumentUploadView: View {
    @Binding var selectedContent: [ContentItem]
    @State private var showingDocumentPicker = false
    
    var body: some View {
        VStack(spacing: 16) {
            if hasDocuments {
                // Show existing documents
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 60)
                        .foregroundColor(.teal.opacity(0.7))
                    
                    Text("Documents Added (\(documentCount))")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 8) {
                        ForEach(documentContent) { item in
                            HStack {
                                Image(systemName: "doc.text")
                                    .foregroundColor(.blue)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.displayName)
                                        .font(.subheadline)
                                        .lineLimit(1)
                                    
                                    Text(item.formattedFileSize)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Button("Remove") {
                                    selectedContent.removeAll { $0.id == item.id }
                                }
                                .font(.caption)
                                .foregroundColor(.red)
                            }
                            .padding(.horizontal, 8)
                        }
                    }
                    
                    Button("Add More") {
                        showingDocumentPicker = true
                    }
                    .font(.subheadline)
                    .buttonStyle(.borderless)
                }
            } else {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 80)
                        .foregroundColor(.teal.opacity(0.7))
                    
                    Text("Add Documents")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("PDFs, Word docs, spreadsheets, and more")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Choose Files") {
                        showingDocumentPicker = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(14)
        .shadow(radius: 4)
        .fileImporter(
            isPresented: $showingDocumentPicker,
            allowedContentTypes: [
                .pdf, .plainText, .rtf, .data
            ],
            allowsMultipleSelection: true
        ) { result in
            Task {
                await handleDocumentSelection(result)
            }
        }
    }
    
    private var hasDocuments: Bool {
        selectedContent.contains { $0.mediaType == .document }
    }
    
    private var documentContent: [ContentItem] {
        selectedContent.filter { $0.mediaType == .document }
    }
    
    private var documentCount: Int {
        documentContent.count
    }
    
    private func handleDocumentSelection(_ result: Result<[URL], Error>) async {
        switch result {
        case .success(let urls):
            for url in urls {
                do {
                    let contentItem = try await ContentManager.shared.createContentItem(from: url)
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
