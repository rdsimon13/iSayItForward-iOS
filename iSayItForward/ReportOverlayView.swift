import SwiftUI

struct ReportOverlayView: View {
    @Binding var isPresented: Bool
    @State private var selectedReason: String = ""
    @State private var additionalDetails: String = ""
    @State private var isAnimating: Bool = false
    
    private let reportReasons = [
        "Inappropriate Content",
        "Spam or Unwanted Messages",
        "Harassment or Bullying",
        "False Information",
        "Copyright Violation",
        "Other"
    ]
    
    var body: some View {
        ZStack {
            // Semi-transparent dark overlay background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissOverlay()
                }
            
            // Centered white modal card
            VStack(spacing: 0) {
                // Header with close button
                HStack {
                    Text("Report Content")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color.brandDarkBlue)
                    
                    Spacer()
                    
                    Button(action: dismissOverlay) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color.white)
                
                Divider()
                
                // Content area
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Why are you reporting this content?")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color.brandDarkBlue)
                        
                        // Report reason selection
                        VStack(spacing: 8) {
                            ForEach(reportReasons, id: \.self) { reason in
                                ReportReasonRow(
                                    reason: reason,
                                    isSelected: selectedReason == reason
                                ) {
                                    selectedReason = reason
                                }
                            }
                        }
                        
                        // Additional details text field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Additional Details (Optional)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Color.brandDarkBlue)
                            
                            TextEditor(text: $additionalDetails)
                                .frame(minHeight: 80)
                                .padding(8)
                                .background(Color.gray.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                        
                        // Action buttons
                        HStack(spacing: 12) {
                            Button("Cancel") {
                                dismissOverlay()
                            }
                            .buttonStyle(SecondaryActionButtonStyle())
                            
                            Button("Submit Report") {
                                submitReport()
                            }
                            .buttonStyle(PrimaryActionButtonStyle())
                            .disabled(selectedReason.isEmpty)
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                }
                .background(Color.white)
            }
            .frame(maxWidth: 320)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
            .scaleEffect(isAnimating ? 1.0 : 0.8)
            .opacity(isAnimating ? 1.0 : 0.0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                isAnimating = true
            }
        }
    }
    
    private func dismissOverlay() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isAnimating = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
    
    private func submitReport() {
        // Submit the report
        print("Report submitted: \(selectedReason)")
        if !additionalDetails.isEmpty {
            print("Additional details: \(additionalDetails)")
        }
        
        // Schedule notification for report submission
        NotificationManager.shared.scheduleReportSubmissionNotification()
        
        // Dismiss the overlay
        dismissOverlay()
    }
}

// Helper view for report reason selection rows
private struct ReportReasonRow: View {
    let reason: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(reason)
                    .font(.body)
                    .foregroundColor(Color.brandDarkBlue)
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? Color.brandDarkBlue : .gray)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isSelected ? Color.brandDarkBlue.opacity(0.1) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.brandDarkBlue : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// Preview for development
struct ReportOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        ReportOverlayView(isPresented: .constant(true))
    }
}