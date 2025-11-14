
import SwiftUI
import UniformTypeIdentifiers

struct DocumentUploadView: View {
    @State private var showingFilePicker = false
    @State private var selectedDocuments: [URL] = []
    @State private var uploadProgress: [URL: Double] = [:]
    @State private var uploadError: String?
    @State private var showingErrorAlert = false

    let allowedTypes = [UTType.pdf, UTType.plainText, UTType("com.microsoft.word.doc")!]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.clear
                    .background(Color.main.ignoresSafeArea())
                
                VStack(spacing: 24) {
                    Text("Upload Document")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color.brandDarkBlue)
                        .padding(.top)
                    
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 80)
                            .foregroundColor(Color.brandDarkBlue.opacity(0.7))
                        
                        Text("Attach documents to enhance your SIF")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color.brandDarkBlue)
                        
                        Text("PDF, DOC, TXT files supported (Max 30MB)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(.white.opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.1), radius: 8, y: 3)
                    
                    Button("Choose Document") {
                        showingFilePicker = true
                    }
                    .buttonStyle(PrimaryActionButtonStyle())
                    
                    // List of selected documents
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(selectedDocuments, id: \.self) { document in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(document.lastPathComponent)
                                            .font(.headline)
                                        if let progress = uploadProgress[document] {
                                            ProgressView(value: progress)
                                                .progressViewStyle(LinearProgressViewStyle())
                                        }
                                    }
                                    Spacer()
                                    Button(action: {
                                        removeDocument(document)
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                }
                                .padding()
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(8)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Upload")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingFilePicker) {
            DocumentPicker(allowedTypes: allowedTypes) { urls in
                handleSelectedDocuments(urls)
            }
        }
        .alert("Upload Error", isPresented: $showingErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(uploadError ?? "Unknown error")
        }
    }
    
    private func handleSelectedDocuments(_ urls: [URL]) {
        for url in urls {
            // Check file size (30MB limit)
            if let fileSize = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize,
               fileSize > 30 * 1024 * 1024 {
                uploadError = "File \(url.lastPathComponent) exceeds 30MB limit"
                showingErrorAlert = true
                continue
            }
            
            if !selectedDocuments.contains(url) {
                selectedDocuments.append(url)
                // Simulate upload progress
                simulateUpload(for: url)
            }
        }
    }
    
    private func simulateUpload(for url: URL) {
        uploadProgress[url] = 0.0
        // In a real app, you would upload to Firebase Storage here
        // This is a simulation
        for i in 1...10 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.3) {
                uploadProgress[url] = Double(i) * 0.1
                if i == 10 {
                    // Upload complete
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        uploadProgress.removeValue(forKey: url)
                    }
                }
            }
        }
    }
    
    private func removeDocument(_ document: URL) {
        selectedDocuments.removeAll { $0 == document }
        uploadProgress.removeValue(forKey: document)
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    let allowedTypes: [UTType]
    let onPick: ([URL]) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: allowedTypes, asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: ([URL]) -> Void
        
        init(onPick: @escaping ([URL]) -> Void) {
            self.onPick = onPick
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            onPick(urls)
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            onPick([])
        }
    }
}

#Preview {
    DocumentUploadView()
        .environmentObject(AuthState())
}
