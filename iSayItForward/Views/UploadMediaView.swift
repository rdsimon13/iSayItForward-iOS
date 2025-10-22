
import SwiftUI

struct UploadMediaView: View {
    @Binding var selectedImage: UIImage?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo")
                .resizable()
                .scaledToFit()
                .frame(height: 120)
                .foregroundColor(.teal.opacity(0.4))

            Text("Upload Media (coming soon)")
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(14)
        .shadow(radius: 4)
    }
}
