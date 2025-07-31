import SwiftUI

/// Progress view for content uploads
struct ContentUploadProgressView: View {
    @ObservedObject var contentManager = ContentManager.shared
    
    var body: some View {
        if contentManager.isUploading && !contentManager.uploadProgress.isEmpty {
            VStack(spacing: 12) {
                Text("Uploading Content...")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                ForEach(Array(contentManager.uploadProgress.keys), id: \.self) { contentId in
                    if let progress = contentManager.uploadProgress[contentId] {
                        UploadProgressRow(progress: progress)
                    }
                }
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(radius: 4)
        }
    }
}

struct UploadProgressRow: View {
    let progress: Double
    
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text("Uploading...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
        }
    }
}