import SwiftUI

struct DocumentUploadView: View {
    @State private var showingFilePicker = false
    @State private var selectedDocument: URL?

    var body: some View {
        NavigationStack {
            ZStack {
                // FIXED: Use the new vibrant gradient background
                Theme.vibrantGradient.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Text("Upload Document")
                        .font(.largeTitle.weight(.bold))
                        .foregroundColor(.white) // FIXED: Use white text for readability
                        .padding(.top)
                    
                    // --- Main content card ---
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 80)
                            .foregroundColor(.white.opacity(0.7)) // FIXED: Use white color
                        
                        Text("Attach documents to enhance your SIF")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white) // FIXED: Use white color
                        
                        Text("PDF, DOC, TXT files supported")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8)) // FIXED: Use white color
                    }
                    .padding()
                    .frostedGlass() // FIXED: Use our new frosted glass style
                    
                    Button("Choose Document") {
                        showingFilePicker = true
                    }
                    .buttonStyle(PrimaryButtonStyle()) // FIXED: Use our updated white button style
                    
                    if let selectedDocument {
                        Text("Selected: \(selectedDocument.lastPathComponent)")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding()
                            .background(.white.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Upload")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingFilePicker) {
            // This is where a real document picker would go
            VStack {
                Text("Document picker would appear here.")
                Button("Close") { showingFilePicker = false }.padding()
            }
        }
    }
}
