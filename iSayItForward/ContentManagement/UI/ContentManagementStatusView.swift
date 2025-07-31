import SwiftUI

/// View to show content management statistics and cache information
struct ContentManagementStatusView: View {
    @StateObject private var contentManager = ContentManager.shared
    @State private var cacheSize: String = "Calculating..."
    @State private var cachedItemsCount: Int = 0
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Content Management")
                .font(.title2)
                .fontWeight(.bold)
            
            // Cache information
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "internaldrive")
                        .foregroundColor(.blue)
                    Text("Cache Information")
                        .font(.headline)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Cache Size:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(cacheSize)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Cached Items:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(cachedItemsCount)")
                            .fontWeight(.medium)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Upload status
            if contentManager.isUploading {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Uploads in Progress")
                            .font(.headline)
                    }
                    
                    ForEach(Array(contentManager.uploadProgress.keys), id: \.self) { contentId in
                        if let progress = contentManager.uploadProgress[contentId] {
                            ProgressView(value: progress)
                                .progressViewStyle(LinearProgressViewStyle(tint: .green))
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            
            // Error display
            if let error = contentManager.error {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.red)
                        Text("Error")
                            .font(.headline)
                            .foregroundColor(.red)
                    }
                    
                    Text(error.localizedDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
            }
            
            // Actions
            VStack(spacing: 12) {
                Button("Clear Cache") {
                    Task {
                        await ContentCache.shared.clearCache()
                        await updateCacheInfo()
                    }
                }
                .buttonStyle(.bordered)
                
                Button("Cleanup Temp Files") {
                    Task {
                        await ContentCompressionService.shared.cleanupTempFiles()
                    }
                }
                .buttonStyle(.bordered)
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            Task {
                await updateCacheInfo()
            }
        }
    }
    
    private func updateCacheInfo() async {
        cacheSize = await ContentCache.shared.getFormattedCacheSize()
        let cachedItems = await ContentCache.shared.getAllCachedContent()
        cachedItemsCount = cachedItems.count
    }
}

struct ContentManagementStatusView_Previews: PreviewProvider {
    static var previews: some View {
        ContentManagementStatusView()
    }
}