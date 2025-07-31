import SwiftUI
import FirebaseAuth

struct SendSIFDemoView: View {
    @State private var testSIF = SIFItem(
        authorUid: "demo-user",
        recipients: ["recipient@example.com"],
        subject: "Test SIF",
        message: "This is a test message to demonstrate the Send SIF functionality with all the new features including upload progress, retry mechanism, and scheduling options.",
        createdDate: Date(),
        scheduledDate: Date()
    )
    
    @State private var showingSendOptions = false
    @StateObject private var sendService = SendSIFService.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.mainAppGradient.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        
                        // Header
                        VStack(spacing: 8) {
                            Text("Send SIF Demo")
                                .font(.largeTitle.weight(.bold))
                                .foregroundColor(.brandDarkBlue)
                            
                            Text("Test the new Send SIF functionality")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        // SIF Preview
                        SIFPreviewSection(sif: testSIF)
                        
                        // Status Information
                        StatusInfoSection(sif: testSIF)
                        
                        // Upload Progress (if in progress)
                        if testSIF.isInProgress {
                            UploadProgressSection(sif: testSIF, progress: testSIF.uploadProgress)
                        }
                        
                        // Error Information (if failed)
                        if testSIF.sendingStatus == .failed {
                            ErrorInfoSection(sif: testSIF)
                        }
                        
                        // Action Buttons
                        ActionButtonsSection(
                            sif: $testSIF,
                            onShowSendOptions: { showingSendOptions = true },
                            onSimulateUpload: simulateUploadProgress,
                            onSimulateFailure: simulateFailedStatus,
                            onReset: resetToDraft
                        )
                        
                        // Features Overview
                        FeaturesOverviewSection()
                        
                        Spacer(minLength: 20)
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingSendOptions) {
            SendOptionsView(sif: $testSIF)
        }
    }
    
    // MARK: - Simulation Methods
    
    private func simulateUploadProgress() {
        testSIF.sendingStatus = .uploading
        testSIF.uploadProgress = 0.0
        testSIF.hasLargeAttachment = true
        testSIF.attachmentSize = 15 * 1024 * 1024 // 15MB
        
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { timer in
            testSIF.uploadProgress += 0.05
            
            if testSIF.uploadProgress >= 1.0 {
                testSIF.uploadProgress = 1.0
                testSIF.sendingStatus = .sent
                timer.invalidate()
            }
        }
    }
    
    private func simulateFailedStatus() {
        testSIF.sendingStatus = .failed
        testSIF.errorMessage = "Network connection failed during upload"
        testSIF.retryCount = 1
        testSIF.uploadProgress = 0.35
    }
    
    private func resetToDraft() {
        testSIF.sendingStatus = .draft
        testSIF.uploadProgress = 0.0
        testSIF.errorMessage = nil
        testSIF.retryCount = 0
        testSIF.hasLargeAttachment = false
        testSIF.attachmentSize = nil
    }
}

// MARK: - Supporting Views

struct SIFPreviewSection: View {
    let sif: SIFItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SIF Preview")
                .font(.headline)
                .foregroundColor(.brandDarkBlue)
            
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(label: "To", value: sif.recipients.joined(separator: ", "))
                InfoRow(label: "Subject", value: sif.subject)
                InfoRow(label: "Message", value: sif.message, isMultiline: true)
                
                if sif.hasLargeAttachment {
                    HStack {
                        Image(systemName: "paperclip")
                            .foregroundColor(.brandYellow)
                        Text("Large attachment (\(formatFileSize(sif.attachmentSize ?? 0)))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            .background(.white.opacity(0.8))
            .cornerRadius(12)
        }
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

struct StatusInfoSection: View {
    let sif: SIFItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Status Information")
                .font(.headline)
                .foregroundColor(.brandDarkBlue)
            
            VStack(spacing: 8) {
                HStack {
                    Text("Current Status:")
                        .font(.body.weight(.medium))
                    Spacer()
                    Text(sif.statusDisplayText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(statusColor.opacity(0.2))
                        .foregroundColor(statusColor)
                        .cornerRadius(8)
                }
                
                HStack {
                    Text("Can Retry:")
                        .font(.body.weight(.medium))
                    Spacer()
                    Text(sif.canRetry ? "Yes" : "No")
                        .foregroundColor(sif.canRetry ? .green : .red)
                }
                
                HStack {
                    Text("In Progress:")
                        .font(.body.weight(.medium))
                    Spacer()
                    Text(sif.isInProgress ? "Yes" : "No")
                        .foregroundColor(sif.isInProgress ? .orange : .gray)
                }
                
                if sif.retryCount > 0 {
                    HStack {
                        Text("Retry Count:")
                            .font(.body.weight(.medium))
                        Spacer()
                        Text("\(sif.retryCount)/3")
                            .foregroundColor(.orange)
                    }
                }
            }
            .padding()
            .background(.white.opacity(0.8))
            .cornerRadius(12)
        }
    }
    
    private var statusColor: Color {
        switch sif.sendingStatus {
        case .draft, .scheduled:
            return .blue
        case .uploading, .sending:
            return .orange
        case .sent:
            return .green
        case .failed:
            return .red
        case .cancelled:
            return .gray
        }
    }
}

struct UploadProgressSection: View {
    let sif: SIFItem
    let progress: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Upload Progress")
                .font(.headline)
                .foregroundColor(.brandDarkBlue)
            
            VStack(spacing: 8) {
                HStack {
                    Text(sif.statusDisplayText)
                        .font(.body.weight(.medium))
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(.body.weight(.bold))
                        .foregroundColor(.brandYellow)
                }
                
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .brandYellow))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
                
                if sif.hasLargeAttachment {
                    Text("Chunked upload for large file in progress...")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(.white.opacity(0.8))
            .cornerRadius(12)
        }
    }
}

struct ErrorInfoSection: View {
    let sif: SIFItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Error Information")
                .font(.headline)
                .foregroundColor(.red)
            
            VStack(alignment: .leading, spacing: 8) {
                if let errorMessage = sif.errorMessage {
                    Text("Error: \(errorMessage)")
                        .font(.body)
                        .foregroundColor(.red)
                }
                
                Text("Retry attempts: \(sif.retryCount)/3")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                if !sif.canRetry {
                    Text("Maximum retry attempts reached")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.top, 4)
                }
            }
            .padding()
            .background(.red.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

struct ActionButtonsSection: View {
    @Binding var sif: SIFItem
    let onShowSendOptions: () -> Void
    let onSimulateUpload: () -> Void
    let onSimulateFailure: () -> Void
    let onReset: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Demo Actions")
                .font(.headline)
                .foregroundColor(.brandDarkBlue)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                
                Button("Send Options") {
                    onShowSendOptions()
                }
                .buttonStyle(PrimaryActionButtonStyle())
                
                Button("Reset Demo") {
                    onReset()
                }
                .buttonStyle(SecondaryActionButtonStyle())
                
                Button("Simulate Upload") {
                    onSimulateUpload()
                }
                .buttonStyle(SecondaryActionButtonStyle())
                .disabled(sif.isInProgress)
                
                Button("Simulate Failure") {
                    onSimulateFailure()
                }
                .buttonStyle(SecondaryActionButtonStyle())
                .disabled(sif.isInProgress)
            }
        }
    }
}

struct FeaturesOverviewSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Implemented Features")
                .font(.headline)
                .foregroundColor(.brandDarkBlue)
            
            VStack(alignment: .leading, spacing: 8) {
                FeatureRow(icon: "clock", title: "Instant & Scheduled Sending")
                FeatureRow(icon: "icloud.and.arrow.up", title: "Large File Chunked Upload")
                FeatureRow(icon: "chart.line.uptrend.xyaxis", title: "Real-time Progress Tracking")
                FeatureRow(icon: "arrow.clockwise", title: "Automatic Retry Mechanism")
                FeatureRow(icon: "app.badge", title: "Background Upload Support")
                FeatureRow(icon: "exclamationmark.triangle", title: "Error Handling & Recovery")
            }
            .padding()
            .background(.white.opacity(0.8))
            .cornerRadius(12)
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    let isMultiline: Bool
    
    init(label: String, value: String, isMultiline: Bool = false) {
        self.label = label
        self.value = value
        self.isMultiline = isMultiline
    }
    
    var body: some View {
        if isMultiline {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(label):")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(value)
                    .font(.body)
                    .lineLimit(3)
            }
        } else {
            HStack {
                Text("\(label):")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(value)
                    .font(.body)
                    .lineLimit(2)
                Spacer()
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.brandYellow)
                .frame(width: 20)
            Text(title)
                .font(.body)
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        }
    }
}

// MARK: - Preview
struct SendSIFDemoView_Previews: PreviewProvider {
    static var previews: some View {
        SendSIFDemoView()
    }
}