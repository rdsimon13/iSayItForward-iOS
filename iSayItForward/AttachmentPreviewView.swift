import SwiftUI
import QuickLook
import AVKit

// MARK: - Attachment Preview View
struct AttachmentPreviewView: View {
    let attachment: Attachment
    @StateObject private var attachmentManager = AttachmentManager.shared
    @State private var showingPreview = false
    @State private var showingShareSheet = false
    @State private var previewImage: UIImage?
    @State private var shareURL: URL?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with file info
            HStack {
                Image(systemName: attachment.systemImageName)
                    .font(.title2)
                    .foregroundColor(attachment.fileType.color)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(attachment.originalName)
                        .font(.headline)
                        .lineLimit(2)
                    
                    HStack {
                        Text(attachment.fileType.displayName)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(attachment.fileType.color.opacity(0.2))
                            .foregroundColor(attachment.fileType.color)
                            .cornerRadius(4)
                        
                        Text(attachment.displaySize)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if attachment.isUploaded {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                        } else {
                            Image(systemName: "clock.circle")
                                .foregroundColor(.orange)
                                .font(.caption)
                        }
                    }
                }
                
                Spacer()
            }
            
            // Preview content
            if attachment.fileType == .image || attachment.fileType == .video {
                previewContent
            }
            
            // Action buttons
            HStack {
                Button(action: { showingPreview = true }) {
                    Label("Preview", systemImage: "eye")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.brandYellow.opacity(0.2))
                        .foregroundColor(.brandYellow)
                        .cornerRadius(8)
                }
                
                Button(action: shareAttachment) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                }
                
                Spacer()
                
                if let progress = attachmentManager.uploadStatuses[attachment.id]?.progress,
                   progress < 1.0 && progress > 0.0 {
                    HStack(spacing: 4) {
                        ProgressView(value: progress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .brandYellow))
                            .frame(width: 50)
                        
                        Text("\(Int(progress * 100))%")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2)
        .onAppear {
            loadPreviewContent()
        }
        .sheet(isPresented: $showingPreview) {
            AttachmentFullPreviewView(attachment: attachment)
        }
        .sheet(isPresented: $showingShareSheet) {
            if let shareURL = shareURL {
                ShareSheet(activityItems: [shareURL])
            }
        }
    }
    
    @ViewBuilder
    private var previewContent: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.1))
                .frame(height: 120)
            
            if let previewImage = previewImage {
                Image(uiImage: previewImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                VStack {
                    Image(systemName: attachment.systemImageName)
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    
                    Text("Loading preview...")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            if attachment.fileType == .video {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.white)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
        }
    }
    
    private func loadPreviewContent() {
        guard attachment.fileType == .image || attachment.fileType == .video else { return }
        
        Task {
            // Try to load thumbnail first
            if let thumbnailURL = attachmentManager.getThumbnailURL(for: attachment) {
                if let image = UIImage(contentsOfFile: thumbnailURL.path) {
                    await MainActor.run {
                        previewImage = image
                    }
                    return
                }
            }
            
            // Fallback to original image if it's small enough
            if attachment.fileType == .image,
               let localURL = attachmentManager.getLocalURL(for: attachment),
               attachment.fileSize < 5 * 1024 * 1024 { // 5MB limit for direct loading
                if let image = UIImage(contentsOfFile: localURL.path) {
                    await MainActor.run {
                        previewImage = image
                    }
                }
            }
        }
    }
    
    private func shareAttachment() {
        guard let localURL = attachmentManager.getLocalURL(for: attachment) else { return }
        shareURL = localURL
        showingShareSheet = true
    }
}

// MARK: - Full Preview View
struct AttachmentFullPreviewView: View {
    let attachment: Attachment
    @StateObject private var attachmentManager = AttachmentManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            Group {
                switch attachment.fileType {
                case .image:
                    ImagePreviewView(attachment: attachment)
                case .video:
                    VideoPreviewView(attachment: attachment)
                default:
                    DocumentPreviewView(attachment: attachment)
                }
            }
            .navigationTitle(attachment.originalName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingShareSheet = true }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let localURL = attachmentManager.getLocalURL(for: attachment) {
                ShareSheet(activityItems: [localURL])
            }
        }
    }
}

// MARK: - Image Preview View
struct ImagePreviewView: View {
    let attachment: Attachment
    @StateObject private var attachmentManager = AttachmentManager.shared
    @State private var image: UIImage?
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            SimultaneousGesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        scale = lastScale * value
                                    }
                                    .onEnded { _ in
                                        lastScale = scale
                                        if scale < 1.0 {
                                            withAnimation {
                                                scale = 1.0
                                                lastScale = 1.0
                                                offset = .zero
                                                lastOffset = .zero
                                            }
                                        } else if scale > 4.0 {
                                            withAnimation {
                                                scale = 4.0
                                                lastScale = 4.0
                                            }
                                        }
                                    },
                                DragGesture()
                                    .onChanged { value in
                                        offset = CGSize(
                                            width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height
                                        )
                                    }
                                    .onEnded { _ in
                                        lastOffset = offset
                                    }
                            )
                        )
                } else {
                    ProgressView("Loading image...")
                        .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        guard let localURL = attachmentManager.getLocalURL(for: attachment) else { return }
        
        Task {
            if let loadedImage = UIImage(contentsOfFile: localURL.path) {
                await MainActor.run {
                    image = loadedImage
                }
            }
        }
    }
}

// MARK: - Video Preview View
struct VideoPreviewView: View {
    let attachment: Attachment
    @StateObject private var attachmentManager = AttachmentManager.shared
    @State private var player: AVPlayer?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let player = player {
                VideoPlayer(player: player)
                    .onAppear {
                        player.play()
                    }
                    .onDisappear {
                        player.pause()
                    }
            } else {
                ProgressView("Loading video...")
                    .foregroundColor(.white)
            }
        }
        .onAppear {
            loadVideo()
        }
    }
    
    private func loadVideo() {
        guard let localURL = attachmentManager.getLocalURL(for: attachment) else { return }
        player = AVPlayer(url: localURL)
    }
}

// MARK: - Document Preview View
struct DocumentPreviewView: View {
    let attachment: Attachment
    @StateObject private var attachmentManager = AttachmentManager.shared
    @State private var previewURL: URL?
    
    var body: some View {
        Group {
            if let previewURL = previewURL {
                QuickLookPreview(url: previewURL)
            } else {
                VStack(spacing: 20) {
                    Image(systemName: attachment.systemImageName)
                        .font(.system(size: 80))
                        .foregroundColor(.gray)
                    
                    Text(attachment.originalName)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    
                    Text(attachment.displaySize)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Document preview not available")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
        }
        .onAppear {
            loadDocument()
        }
    }
    
    private func loadDocument() {
        previewURL = attachmentManager.getLocalURL(for: attachment)
    }
}

// MARK: - QuickLook Preview
struct QuickLookPreview: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
    }
    
    class Coordinator: NSObject, QLPreviewControllerDataSource {
        let url: URL
        
        init(url: URL) {
            self.url = url
        }
        
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return 1
        }
        
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            return url as QLPreviewItem
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - AttachmentType Color Extension
extension AttachmentType {
    var color: Color {
        switch self {
        case .image: return .blue
        case .video: return .purple
        case .document: return .orange
        case .audio: return .green
        case .unknown: return .gray
        }
    }
}