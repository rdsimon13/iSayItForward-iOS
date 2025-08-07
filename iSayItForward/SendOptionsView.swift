import SwiftUI

struct SendOptionsView: View {
    // MARK: - Properties
    @Binding var sif: SIFItem
    @StateObject private var sendService = SendSIFService.shared
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State Variables
    @State private var sendMode: SendMode = .instant
    @State private var scheduleDate = Date()
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isSending = false
    
    // MARK: - Send Mode Enum
    enum SendMode: String, CaseIterable {
        case instant = "Send Now"
        case schedule = "Schedule"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.mainAppGradient.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // Send Mode Picker
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Send Options")
                                .font(.headline)
                                .foregroundColor(.brandDarkBlue)
                            
                            Picker("Send Mode", selection: $sendMode) {
                                ForEach(SendMode.allCases, id: \.self) { mode in
                                    Text(mode.rawValue)
                                        .tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)
                            .background(.white.opacity(0.3))
                            .cornerRadius(8)
                        }
                        
                        // Schedule Date Picker (only shown when scheduling)
                        if sendMode == .schedule {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Schedule Date & Time")
                                    .font(.headline)
                                    .foregroundColor(.brandDarkBlue)
                                
                                DatePicker(
                                    "Select Date & Time",
                                    selection: $scheduleDate,
                                    in: Date()...,
                                    displayedComponents: [.date, .hourAndMinute]
                                )
                                .datePickerStyle(.graphical)
                                .padding()
                                .background(.white.opacity(0.85))
                                .cornerRadius(16)
                            }
                        }
                        
                        // SIF Preview
                        SIFPreviewCard(sif: sif)
                        
                        // Upload Progress (if uploading)
                        if let sifID = sif.id, 
                           let progress = sendService.uploadProgress[sifID],
                           sif.isInProgress {
                            UploadProgressView(progress: progress, sif: sif)
                        }
                        
                        // Error Message (if failed)
                        if sif.sendingStatus == .failed {
                            ErrorRetryView(sif: sif, onRetry: retryUpload)
                        }
                        
                        Spacer(minLength: 20)
                        
                        // Action Buttons
                        VStack(spacing: 12) {
                            if sif.isInProgress {
                                // Cancel Button
                                Button("Cancel Upload") {
                                    cancelUpload()
                                }
                                .buttonStyle(SecondaryActionButtonStyle())
                            } else {
                                // Send Button
                                Button(sendMode == .instant ? "Send Now" : "Schedule SIF") {
                                    performSend()
                                }
                                .buttonStyle(PrimaryActionButtonStyle())
                                .disabled(isSending)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Send SIF")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(sif.isInProgress)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !sif.isInProgress {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
            }
        }
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            // Set default schedule date to one hour from now
            scheduleDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        }
    }
    
    // MARK: - Actions
    
    private func performSend() {
        isSending = true
        
        Task {
            do {
                switch sendMode {
                case .instant:
                    try await sendService.sendInstantly(sif)
                    await showSuccess(message: "SIF sent successfully!")
                    
                case .schedule:
                    try await sendService.scheduleForSending(sif, at: scheduleDate)
                    await showSuccess(message: "SIF scheduled successfully!")
                }
                
                await MainActor.run {
                    dismiss()
                }
                
            } catch {
                await showError(message: "Failed to send SIF: \(error.localizedDescription)")
            }
            
            await MainActor.run {
                isSending = false
            }
        }
    }
    
    private func retryUpload() {
        Task {
            do {
                try await sendService.retrySending(sif)
                await showSuccess(message: "Retry initiated successfully!")
            } catch {
                await showError(message: "Failed to retry: \(error.localizedDescription)")
            }
        }
    }
    
    private func cancelUpload() {
        guard let sifID = sif.id else { return }
        sendService.cancelUpload(for: sifID)
        dismiss()
    }
    
    @MainActor
    private func showSuccess(message: String) {
        alertTitle = "Success"
        alertMessage = message
        showingAlert = true
    }
    
    @MainActor
    private func showError(message: String) {
        alertTitle = "Error"
        alertMessage = message
        showingAlert = true
    }
}

// MARK: - Supporting Views

struct SIFPreviewCard: View {
    let sif: SIFItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SIF Preview")
                .font(.headline)
                .foregroundColor(.brandDarkBlue)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("To:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(sif.recipients.joined(separator: ", "))
                        .font(.body)
                        .lineLimit(2)
                }
                
                HStack {
                    Text("Subject:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(sif.subject)
                        .font(.body)
                        .lineLimit(1)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Message:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(sif.message)
                        .font(.body)
                        .lineLimit(3)
                }
                
                if sif.attachmentURL != nil {
                    HStack {
                        Image(systemName: "paperclip")
                            .foregroundColor(.brandYellow)
                        Text("Attachment included")
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
}

struct UploadProgressView: View {
    let progress: Double
    let sif: SIFItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Upload Progress")
                .font(.headline)
                .foregroundColor(.brandDarkBlue)
            
            VStack(spacing: 8) {
                HStack {
                    Text(sif.statusDisplayText)
                        .font(.body)
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .brandYellow))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
                
                if sif.hasLargeAttachment {
                    Text("Large file upload in progress...")
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

struct ErrorRetryView: View {
    let sif: SIFItem
    let onRetry: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Upload Failed")
                .font(.headline)
                .foregroundColor(.red)
            
            VStack(spacing: 12) {
                if let errorMessage = sif.errorMessage {
                    Text(errorMessage)
                        .font(.body)
                        .foregroundColor(.red)
                }
                
                Text("Retry attempts: \(sif.retryCount)/3")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                if sif.canRetry {
                    Button("Retry Upload") {
                        onRetry()
                    }
                    .buttonStyle(SecondaryActionButtonStyle())
                } else {
                    Text("Maximum retry attempts reached")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            .padding()
            .background(.white.opacity(0.8))
            .cornerRadius(12)
        }
    }
}

// MARK: - Preview
struct SendOptionsView_Previews: PreviewProvider {
    static var previews: some View {
        SendOptionsView(sif: .constant(SIFItem(
            authorUid: "test",
            recipients: ["john@example.com"],
            subject: "Test SIF",
            message: "This is a test message",
            createdDate: Date(),
            scheduledDate: Date()
        )))
    }
}