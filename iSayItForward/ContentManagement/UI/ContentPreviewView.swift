import SwiftUI
import AVKit
import PDFKit
import QuickLook

/// View for previewing different types of content
struct ContentPreviewView: View {
    let contentItem: ContentItem
    @Environment(\.dismiss) private var dismiss
    @StateObject private var contentManager = ContentManager.shared
    @State private var localURL: URL?
    @State private var isLoading = false
    @State private var error: Error?
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = error {
                    ErrorView(error: error) {
                        Task { await loadContent() }
                    }
                } else if let localURL = localURL {
                    ContentDisplayView(contentItem: contentItem, localURL: localURL)
                } else {
                    EmptyView()
                }
            }
            .navigationTitle(contentItem.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                if localURL != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        ShareLink(item: localURL!) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
        }
        .task {
            await loadContent()
        }
    }
    
    private func loadContent() async {
        isLoading = true
        error = nil
        
        do {
            if contentItem.hasLocalFile {
                localURL = contentItem.localURL
            } else if contentItem.isUploaded {
                localURL = try await contentManager.downloadContent(contentItem)
            } else {
                localURL = contentItem.localURL
            }
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
}

struct ContentDisplayView: View {
    let contentItem: ContentItem
    let localURL: URL
    
    var body: some View {
        switch contentItem.mediaType {
        case .photo:
            PhotoPreviewView(url: localURL)
        case .video:
            VideoPreviewView(url: localURL)
        case .audio:
            AudioPreviewView(url: localURL, contentItem: contentItem)
        case .text:
            TextPreviewView(url: localURL)
        case .document:
            DocumentPreviewView(url: localURL)
        }
    }
}

struct PhotoPreviewView: View {
    let url: URL
    @State private var image: UIImage?
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipped()
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        DispatchQueue.global(qos: .userInitiated).async {
            if let loadedImage = UIImage(contentsOfFile: url.path) {
                DispatchQueue.main.async {
                    image = loadedImage
                }
            }
        }
    }
}

struct VideoPreviewView: View {
    let url: URL
    
    var body: some View {
        VideoPlayer(player: AVPlayer(url: url))
            .aspectRatio(16/9, contentMode: .fit)
    }
}

struct AudioPreviewView: View {
    let url: URL
    let contentItem: ContentItem
    @State private var player: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var currentTime: TimeInterval = 0
    @State private var duration: TimeInterval = 0
    @State private var timer: Timer?
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Audio visualization
            VStack(spacing: 20) {
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.blue)
                    .scaleEffect(isPlaying ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isPlaying)
                
                Text(contentItem.displayName)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Progress slider
            VStack(spacing: 10) {
                Slider(value: $currentTime, in: 0...duration) { editing in
                    if !editing {
                        player?.currentTime = currentTime
                    }
                }
                .disabled(duration == 0)
                
                HStack {
                    Text(timeString(from: currentTime))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(timeString(from: duration))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            
            // Play controls
            HStack(spacing: 40) {
                Button(action: rewind) {
                    Image(systemName: "gobackward.15")
                        .font(.title2)
                }
                
                Button(action: togglePlayback) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                }
                
                Button(action: fastForward) {
                    Image(systemName: "goforward.15")
                        .font(.title2)
                }
            }
            
            Spacer()
        }
        .onAppear {
            setupAudioPlayer()
        }
        .onDisappear {
            stopPlayback()
        }
    }
    
    private func setupAudioPlayer() {
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            duration = player?.duration ?? 0
        } catch {
            print("Failed to setup audio player: \(error)")
        }
    }
    
    private func togglePlayback() {
        guard let player = player else { return }
        
        if player.isPlaying {
            player.pause()
            isPlaying = false
            stopTimer()
        } else {
            player.play()
            isPlaying = true
            startTimer()
        }
    }
    
    private func stopPlayback() {
        player?.stop()
        isPlaying = false
        stopTimer()
    }
    
    private func rewind() {
        guard let player = player else { return }
        let newTime = max(0, player.currentTime - 15)
        player.currentTime = newTime
        currentTime = newTime
    }
    
    private func fastForward() {
        guard let player = player else { return }
        let newTime = min(duration, player.currentTime + 15)
        player.currentTime = newTime
        currentTime = newTime
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if let player = player {
                currentTime = player.currentTime
                
                if !player.isPlaying {
                    isPlaying = false
                    stopTimer()
                }
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct TextPreviewView: View {
    let url: URL
    @State private var content: String = ""
    
    var body: some View {
        ScrollView {
            Text(content)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear {
            loadText()
        }
    }
    
    private func loadText() {
        DispatchQueue.global(qos: .userInitiated).async {
            if let textContent = try? String(contentsOf: url) {
                DispatchQueue.main.async {
                    content = textContent
                }
            }
        }
    }
}

struct DocumentPreviewView: View {
    let url: URL
    @State private var showingQuickLook = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 100))
                .foregroundColor(.blue)
            
            Text("Document Preview")
                .font(.headline)
            
            Text(url.lastPathComponent)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Open Document") {
                showingQuickLook = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .sheet(isPresented: $showingQuickLook) {
            QuickLookView(url: url)
        }
    }
}

struct QuickLookView: UIViewControllerRepresentable {
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

struct ErrorView: View {
    let error: Error
    let retry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("Error Loading Content")
                .font(.headline)
            
            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Try Again", action: retry)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}