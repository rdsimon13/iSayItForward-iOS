import SwiftUI
import AVFoundation

struct VoiceNoteView: View {
    @State private var isRecording = false
    @State private var recordingTime: TimeInterval = 0
    @State private var audioRecorder: AVAudioRecorder?
    @State private var audioPlayer: AVAudioPlayer?
    @State private var audioURL: URL?
    @State private var timer: Timer?
    @State private var isPlaying = false
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "mic.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(height: 60)
                .foregroundColor(isRecording ? .red : .teal.opacity(0.7))
            
            Text("Voice Note")
                .font(.headline)
            
            if let audioURL = audioURL {
                Text("Recording available (\(formatTime(recordingTime)))")
                    .font(.caption)
                
                HStack {
                    Button(action: playRecording) {
                        Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                            .font(.title)
                    }
                    .disabled(isRecording)
                    
                    Button(action: deleteRecording) {
                        Image(systemName: "trash.circle.fill")
                            .font(.title)
                            .foregroundColor(.red)
                    }
                    .disabled(isRecording)
                }
            } else {
                Text("No recording")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Button(action: toggleRecording) {
                Text(isRecording ? "Stop Recording" : "Start Recording")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(isRecording ? Color.red : Color.teal)
                    .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(14)
        .shadow(radius: 4)
        .onAppear {
            setupRecorder()
        }
        .onDisappear {
            stopRecording()
        }
    }
    
    private func setupRecorder() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
            
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioFilename = documentsPath.appendingPathComponent("voiceNote.m4a")
            audioURL = audioFilename
            
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 12000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.prepareToRecord()
        } catch {
            print("Failed to setup recorder: \(error)")
        }
    }
    
    private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        audioRecorder?.record()
        isRecording = true
        recordingTime = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            recordingTime += 1
        }
    }
    
    private func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        timer?.invalidate()
        timer = nil
    }
    
    private func playRecording() {
        guard let audioURL = audioURL else { return }
        
        if isPlaying {
            audioPlayer?.stop()
            isPlaying = false
        } else {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
                audioPlayer?.play()
                isPlaying = true
                
                // Stop playing when finished
                DispatchQueue.main.asyncAfter(deadline: .now() + (audioPlayer?.duration ?? 0)) {
                    isPlaying = false
                }
            } catch {
                print("Playback failed: \(error)")
            }
        }
    }
    
    private func deleteRecording() {
        audioPlayer?.stop()
        isPlaying = false
        guard let audioURL = audioURL else { return }
        try? FileManager.default.removeItem(at: audioURL)
        self.audioURL = nil
        recordingTime = 0
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
