
import SwiftUI

struct DocumentUploadView: View {
    @State private var showingFilePicker = false
    @State private var selectedDocument: URL?

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
                        
                        Text("PDF, DOC, TXT files supported")
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
                    
                    if selectedDocument != nil {
                        Text("Document selected!")
                            .font(.subheadline)
                            .foregroundColor(.green)
                            .padding()
                            .background(.white.opacity(0.8))
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
            // In a real app, this would be a document picker
            VStack {
                Text("Document picker functionality")
                Text("Coming soon...")
                    .foregroundColor(.gray)
                Button("Cancel") {
                    showingFilePicker = false
                }
                .padding()
            }
            .padding()
        }
    }
}
#Preview {
    DocumentUploadView()
        .environmentObject(AuthState())
}
