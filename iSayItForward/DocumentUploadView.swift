
import SwiftUI

struct DocumentUploadView: View {
    @Binding var selectedDocument: URL?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.fill")
                .resizable()
                .scaledToFit()
                .frame(height: 100)
                .foregroundColor(.teal.opacity(0.7))
            Text("Document upload coming soon.")
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(14)
        .shadow(radius: 4)
    }
}
