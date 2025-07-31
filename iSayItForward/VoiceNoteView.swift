
import SwiftUI

struct VoiceNoteView: View {
    @Binding var selectedContent: [ContentItem]
    @State private var showingAudioRecorder = false
    
    var body: some View {
        VStack(spacing: 16) {
            if hasAudioContent {
                // Show existing audio content
                VStack(spacing: 12) {
                    Image(systemName: "waveform.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 60)
                        .foregroundColor(.teal.opacity(0.7))
                    
                    Text("Voice Note Added")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let audioItem = audioContent {
                        HStack {
                            Text(audioItem.displayName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button("Remove") {
                                selectedContent.removeAll { $0.id == audioItem.id }
                            }
                            .font(.caption)
                            .foregroundColor(.red)
                        }
                    }
                    
                    Button("Record New") {
                        showingAudioRecorder = true
                    }
                    .font(.subheadline)
                    .buttonStyle(.borderless)
                }
            } else {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "mic.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 80)
                        .foregroundColor(.teal.opacity(0.7))
                    
                    Text("Add Voice Note")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Record a voice message")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button("Start Recording") {
                        showingAudioRecorder = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(14)
        .shadow(radius: 4)
        .sheet(isPresented: $showingAudioRecorder) {
            AudioRecorderView { audioURL in
                Task {
                    do {
                        let contentItem = try await ContentManager.shared.createContentItem(from: audioURL)
                        
                        // Replace existing audio content or add new
                        selectedContent.removeAll { $0.mediaType == .audio }
                        selectedContent.append(contentItem)
                    } catch {
                        print("Failed to add audio content: \(error)")
                    }
                }
            }
        }
    }
    
    private var hasAudioContent: Bool {
        selectedContent.contains { $0.mediaType == .audio }
    }
    
    private var audioContent: ContentItem? {
        selectedContent.first { $0.mediaType == .audio }
    }
}
