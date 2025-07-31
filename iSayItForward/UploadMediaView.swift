
import SwiftUI

struct UploadMediaView: View {
    @Binding var selectedContent: [ContentItem]
    @State private var showingMediaPicker = false
    
    var body: some View {
        VStack(spacing: 16) {
            if selectedContent.isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 80)
                        .foregroundColor(.teal.opacity(0.6))
                    
                    Text("Add Media")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Photos, videos, audio, and documents")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Choose Media") {
                        showingMediaPicker = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                // Content preview
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Attached Media (\(selectedContent.count))")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button("Add More") {
                            showingMediaPicker = true
                        }
                        .font(.caption)
                        .buttonStyle(.borderless)
                    }
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ForEach(selectedContent) { item in
                            ContentThumbnailView(item: item) {
                                selectedContent.removeAll { $0.id == item.id }
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(14)
        .shadow(radius: 4)
        .sheet(isPresented: $showingMediaPicker) {
            MediaPickerView(
                selectedContent: $selectedContent,
                allowedTypes: [.photo, .video, .audio, .document],
                maxSelections: 5
            )
        }
    }
}

struct ContentThumbnailView: View {
    let item: ContentItem
    let onRemove: () -> Void
    @State private var thumbnail: UIImage?
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
                .frame(height: 80)
                .overlay(
                    Group {
                        if let thumbnail = thumbnail {
                            Image(uiImage: thumbnail)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .clipped()
                        } else {
                            VStack(spacing: 4) {
                                Image(systemName: item.mediaType.iconName)
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                                
                                Text(item.mediaType.displayName)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.red)
                    .background(Color.white)
                    .clipShape(Circle())
            }
            .offset(x: 6, y: -6)
        }
        .onAppear {
            loadThumbnail()
        }
    }
    
    private func loadThumbnail() {
        Task {
            thumbnail = await ContentManager.shared.generateThumbnail(for: item)
        }
    }
}
