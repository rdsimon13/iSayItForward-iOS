
import SwiftUI
import AVFoundation

struct VoiceNoteView: View {
    @Binding var contentAttachments: [ContentAttachment]
    
    @State private var isRecording = false
    @State private var recordingTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack(spacing: 16) {
            // Recording indicator
            Image(systemName: isRecording ? "mic.circle.fill" : "mic.circle")
                .resizable()
                .scaledToFit()
                .frame(height: 80)
                .foregroundColor(isRecording ? .red : .teal.opacity(0.7))
                .scaleEffect(isRecording ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isRecording)
            
            if isRecording {
                Text(formatRecordingTime(recordingTime))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
            } else {
                Text("Voice Recording")
                    .font(.headline)
                    .foregroundColor(.teal)
            }
            
            // Recording controls
            HStack(spacing: 20) {
                if isRecording {
                    Button("Stop") {
                        stopRecording()
                    }
                    .buttonStyle(SecondaryActionButtonStyle())
                } else {
                    Button("Start Recording") {
                        startRecording()
                    }
                    .buttonStyle(PrimaryActionButtonStyle())
                }
            }
            
            // Show existing audio recordings
            if !contentAttachments.filter({ $0.contentType == .audio }).isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Audio Recordings")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.teal)
                    
                    ForEach(contentAttachments.filter { $0.contentType == .audio }) { attachment in
                        audioAttachmentRow(attachment)
                    }
                }
                .padding(.top)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(14)
        .shadow(radius: 4)
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Audio Recording"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .onDisappear {
            if isRecording {
                stopRecording()
            }
        }
    }
    
    private func audioAttachmentRow(_ attachment: ContentAttachment) -> some View {
        HStack {
            Image(systemName: "waveform.circle.fill")
                .foregroundColor(.teal)
            
            VStack(alignment: .leading) {
                Text(attachment.fileName)
                    .font(.subheadline)
                    .lineLimit(1)
                HStack {
                    Text(ByteFormatter.format(bytes: attachment.fileSize))
                        .font(.caption)
                        .foregroundColor(.gray)
                    if let duration = attachment.duration {
                        Text("• \(formatDuration(duration))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Spacer()
            
            Button("Remove") {
                removeAttachment(attachment)
            }
            .font(.caption)
            .foregroundColor(.red)
        }
        .padding(.vertical, 4)
    }
    
    private func startRecording() {
        // Request microphone permission
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                if granted {
                    beginRecording()
                } else {
                    alertMessage = "Microphone access is required for voice recording."
                    showingAlert = true
                }
            }
        }
    }
    
    private func beginRecording() {
        isRecording = true
        recordingTime = 0
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            recordingTime += 0.1
        }
        
        // In a real app, this would start actual audio recording
        // For now, we'll simulate recording and create a sample attachment
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Simulation - in real app would use AVAudioRecorder
        }
    }
    
    private func stopRecording() {
        isRecording = false
        timer?.invalidate()
        timer = nil
        
        // Create a sample audio attachment
        let attachment = ContentAttachment(
            contentType: .audio,
            fileName: "recording_\(Date().timeIntervalSince1970).m4a",
            fileSize: Int(recordingTime * 8000), // Approximate size calculation
            metadata: [
                "duration": "\(recordingTime)",
                "format": "m4a",
                "source": "voice_recording"
            ]
        )
        
        // Add duration to the attachment (would be done during creation in real implementation)
        var modifiedAttachment = attachment
        // Since ContentAttachment properties are let, we create a new one with duration
        // In a real implementation, we'd have a mutable way to set this
        
        contentAttachments.append(attachment)
        
        alertMessage = "Voice recording saved successfully!"
        showingAlert = true
    }
    
    private func removeAttachment(_ attachment: ContentAttachment) {
        contentAttachments.removeAll { $0.id == attachment.id }
    }
    
    private func formatRecordingTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let centiseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, centiseconds)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
