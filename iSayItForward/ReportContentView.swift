import SwiftUI

struct ReportContentView: View {
    let contentId: String
    let contentAuthorId: String
    @StateObject private var contentSafetyService = ContentSafetyService()
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedReason: ReportReason?
    @State private var description: String = ""
    @State private var isSubmitting = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.mainAppGradient.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Report Content")
                                .font(.title2.weight(.bold))
                            Text("Help us keep the community safe by reporting inappropriate content.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.white.opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
                        
                        // Reason Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Reason for Report")
                                .font(.headline)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(ReportReason.allCases, id: \.self) { reason in
                                    ReasonSelectionCard(
                                        reason: reason,
                                        isSelected: selectedReason == reason
                                    ) {
                                        selectedReason = reason
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(.white.opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
                        
                        // Additional Description
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Additional Details (Optional)")
                                .font(.headline)
                            
                            TextEditor(text: $description)
                                .frame(minHeight: 80)
                                .padding(8)
                                .background(Color.gray.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                            
                            Text("Provide any additional context that might help us understand the issue.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(.white.opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
                        
                        // Submit Button
                        Button(action: submitReport) {
                            HStack {
                                if isSubmitting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                }
                                Text(isSubmitting ? "Submitting..." : "Submit Report")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(selectedReason != nil ? Color.red : Color.gray)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(selectedReason == nil || isSubmitting)
                        .padding(.horizontal)
                    }
                    .padding()
                }
            }
            .foregroundColor(Color.brandDarkBlue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK") {
                if alertTitle == "Report Submitted" {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func submitReport() {
        guard let reason = selectedReason else { return }
        
        isSubmitting = true
        
        Task {
            do {
                try await contentSafetyService.reportContent(
                    contentId: contentId,
                    contentAuthorId: contentAuthorId,
                    reason: reason,
                    description: description.isEmpty ? nil : description
                )
                
                await MainActor.run {
                    isSubmitting = false
                    alertTitle = "Report Submitted"
                    alertMessage = "Thank you for helping us keep the community safe. We'll review your report and take appropriate action."
                    showingAlert = true
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    alertTitle = "Error"
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
        }
    }
}

struct ReasonSelectionCard: View {
    let reason: ReportReason
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: iconForReason(reason))
                        .foregroundColor(isSelected ? .white : .red)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                    }
                }
                
                Text(reason.displayName)
                    .font(.subheadline.weight(.semibold))
                    .multilineTextAlignment(.leading)
                    .foregroundColor(isSelected ? .white : Color.brandDarkBlue)
                
                Text(reason.description)
                    .font(.caption)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Color.red : Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.red : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func iconForReason(_ reason: ReportReason) -> String {
        switch reason {
        case .inappropriateContent:
            return "exclamationmark.triangle"
        case .harassment:
            return "person.2.slash"
        case .spam:
            return "hand.raised"
        case .hateSpeech:
            return "bubble.left.and.exclamationmark.bubble.right"
        case .violence:
            return "hand.raised.slash"
        case .misinformation:
            return "questionmark.circle"
        case .copyright:
            return "c.circle"
        case .other:
            return "ellipsis.circle"
        }
    }
}

struct ReportContentView_Previews: PreviewProvider {
    static var previews: some View {
        ReportContentView(
            contentId: "sample-content-id",
            contentAuthorId: "sample-author-id"
        )
    }
}