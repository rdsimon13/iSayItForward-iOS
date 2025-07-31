import SwiftUI
import AVFoundation

/// View for recording audio
struct AudioRecorderView: View {
    let onAudioRecorded: (URL) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var audioRecorder = AudioRecorder()
    @State private var isRecording = false
    @State private var recordingTime: TimeInterval = 0
    @State private var timer: Timer?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                
                // Recording visualization
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(isRecording ? Color.red.opacity(0.3) : Color.gray.opacity(0.3))
                            .frame(width: 200, height: 200)
                            .scaleEffect(isRecording ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isRecording)
                        
                        Image(systemName: "mic.fill")
                            .font(.system(size: 60))
                            .foregroundColor(isRecording ? .red : .gray)
                    }
                    
                    Text(timeString(from: recordingTime))
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    if isRecording {
                        Text("Recording...")
                            .font(.headline)
                            .foregroundColor(.red)
                    } else {
                        Text("Tap to start recording")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                // Controls
                HStack(spacing: 40) {
                    // Cancel button
                    Button("Cancel") {
                        if isRecording {
                            stopRecording()
                        }
                        dismiss()
                    }
                    .font(.headline)
                    .foregroundColor(.red)
                    
                    // Record/Stop button
                    Button(action: {
                        if isRecording {
                            stopRecording()
                        } else {
                            startRecording()
                        }
                    }) {
                        Image(systemName: isRecording ? "stop.circle.fill" : "circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(isRecording ? .red : .blue)
                    }
                    .disabled(audioRecorder.isSetupFailed)
                    
                    // Done button (only shown after recording)
                    Button("Done") {
                        if let recordedURL = audioRecorder.recordedURL {
                            onAudioRecorded(recordedURL)
                        }
                        dismiss()
                    }
                    .font(.headline)
                    .foregroundColor(.blue)
                    .opacity(audioRecorder.recordedURL != nil ? 1.0 : 0.3)
                    .disabled(audioRecorder.recordedURL == nil)
                }
                .padding(.bottom, 50)
            }
            .navigationTitle("Voice Recording")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") {
                dismiss()
            })
        }
        .onAppear {
            setupAudioSession()
        }
        .onDisappear {
            stopRecording()
        }
    }
    
    // MARK: - Private Methods
    
    private func setupAudioSession() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                if granted {
                    audioRecorder.setupRecording()
                }
            }
        }
    }
    
    private func startRecording() {
        audioRecorder.startRecording()
        isRecording = true
        recordingTime = 0
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            recordingTime += 0.1
        }
    }
    
    private func stopRecording() {
        audioRecorder.stopRecording()
        isRecording = false
        timer?.invalidate()
        timer = nil
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        let hundredths = Int((timeInterval.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, hundredths)
    }
}

// MARK: - Audio Recorder
class AudioRecorder: ObservableObject {
    private var audioRecorder: AVAudioRecorder?
    @Published var isSetupFailed = false
    @Published var recordedURL: URL?
    
    func setupRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
            
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioURL = documentsPath.appendingPathComponent("recording_\(UUID().uuidString).m4a")
            
            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
            audioRecorder?.prepareToRecord()
            
        } catch {
            isSetupFailed = true
            print("Failed to setup audio recording: \(error)")
        }
    }
    
    func startRecording() {
        audioRecorder?.record()
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        recordedURL = audioRecorder?.url
    }
}