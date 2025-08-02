import SwiftUI
import FirebaseFirestore

struct ReportDetailView: View {
    let report: Report
    
    @StateObject private var contentSafetyManager = ContentSafetyManager()
    @Environment(\.dismiss) private var dismiss
    
    @State private var moderatorNotes: String = ""
    @State private var isUpdating = false
    @State private var showingActionSheet = false
    @State private var selectedAction: ReportAction?
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            Color.mainAppGradient.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // Report Summary Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Report Summary")
                                .font(.headline.weight(.bold))
                                .foregroundColor(Color.brandDarkBlue)
                            
                            Spacer()
                            
                            StatusBadge(status: report.status)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            DetailRow(
                                icon: "flag.fill",
                                title: "Category",
                                value: report.category.displayName
                            )
                            
                            DetailRow(
                                icon: "calendar",
                                title: "Reported",
                                value: report.createdDate.formatted(date: .abbreviated, time: .shortened)
                            )
                            
                            DetailRow(
                                icon: "doc.text",
                                title: "Content ID",
                                value: report.reportedContentId
                            )
                            
                            DetailRow(
                                icon: "person",
                                title: "Content Author",
                                value: report.reportedContentAuthorUid
                            )
                            
                            if let reviewDate = report.reviewedDate {
                                DetailRow(
                                    icon: "checkmark.circle",
                                    title: "Reviewed",
                                    value: reviewDate.formatted(date: .abbreviated, time: .shortened)
                                )
                            }
                        }
                    }
                    .padding()
                    .background(.white.opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
                    
                    // Reporter's Reason
                    if !report.reason.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Reporter's Details")
                                .font(.headline.weight(.bold))
                                .foregroundColor(Color.brandDarkBlue)
                            
                            Text(report.reason)
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                        .padding()
                        .background(.white.opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
                    }
                    
                    // Existing Moderator Notes
                    if let existingNotes = report.moderatorNotes, !existingNotes.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Previous Moderator Notes")
                                .font(.headline.weight(.bold))
                                .foregroundColor(Color.brandDarkBlue)
                            
                            Text(existingNotes)
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                        .padding()
                        .background(.white.opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
                    }
                    
                    // Moderator Actions (only show if report is pending or under review)
                    if report.status == .pending || report.status == .underReview {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Moderator Actions")
                                .font(.headline.weight(.bold))
                                .foregroundColor(Color.brandDarkBlue)
                            
                            // Moderator Notes Input
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Add Notes (Optional)")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.primary)
                                
                                TextEditor(text: $moderatorNotes)
                                    .frame(minHeight: 80)
                                    .padding(8)
                                    .background(Color.gray.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            
                            // Action Buttons
                            VStack(spacing: 8) {
                                Button("Mark as Under Review") {
                                    selectedAction = .underReview
                                    showingActionSheet = true
                                }
                                .buttonStyle(SecondaryActionButtonStyle())
                                .disabled(report.status == .underReview)
                                
                                HStack(spacing: 12) {
                                    Button("Resolve") {
                                        selectedAction = .resolve
                                        showingActionSheet = true
                                    }
                                    .buttonStyle(PrimaryActionButtonStyle())
                                    .frame(maxWidth: .infinity)
                                    
                                    Button("Dismiss") {
                                        selectedAction = .dismiss
                                        showingActionSheet = true
                                    }
                                    .buttonStyle(SecondaryActionButtonStyle())
                                    .frame(maxWidth: .infinity)
                                }
                            }
                        }
                        .padding()
                        .background(.white.opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
                    }
                    
                    Spacer()
                }
                .padding()
            }
        }
        .navigationTitle("Report Details")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Confirm Action", isPresented: $showingActionSheet) {
            if let action = selectedAction {
                Button(action.confirmButtonTitle) {
                    performAction(action)
                }
                
                Button("Cancel", role: .cancel) { }
            }
        } message: {
            if let action = selectedAction {
                Text(action.confirmationMessage)
            }
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .disabled(isUpdating)
        .overlay {
            if isUpdating {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.2)
                        
                        Text("Updating report...")
                            .foregroundColor(.white)
                            .font(.subheadline)
                    }
                    .padding()
                    .background(.black.opacity(0.7))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
    
    private func performAction(_ action: ReportAction) {
        isUpdating = true
        
        Task {
            do {
                let status = action.reportStatus
                let notes = moderatorNotes.trimmingCharacters(in: .whitespacesAndNewlines)
                
                try await contentSafetyManager.updateReportStatus(
                    reportId: report.id ?? "",
                    status: status,
                    moderatorNotes: notes.isEmpty ? nil : notes
                )
                
                await MainActor.run {
                    isUpdating = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isUpdating = false
                    errorMessage = error.localizedDescription
                    showingErrorAlert = true
                }
            }
        }
    }
}

// MARK: - Report Action Enum

enum ReportAction {
    case underReview
    case resolve
    case dismiss
    
    var reportStatus: ReportStatus {
        switch self {
        case .underReview:
            return .underReview
        case .resolve:
            return .resolved
        case .dismiss:
            return .dismissed
        }
    }
    
    var confirmButtonTitle: String {
        switch self {
        case .underReview:
            return "Mark Under Review"
        case .resolve:
            return "Resolve Report"
        case .dismiss:
            return "Dismiss Report"
        }
    }
    
    var confirmationMessage: String {
        switch self {
        case .underReview:
            return "Mark this report as under review?"
        case .resolve:
            return "Resolve this report? This indicates the content was found to violate guidelines and appropriate action was taken."
        case .dismiss:
            return "Dismiss this report? This indicates the content was found to be acceptable."
        }
    }
}

// MARK: - Helper Components

private struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.body.weight(.medium))
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Preview

struct ReportDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ReportDetailView(report: Report(
                reporterUid: "reporter123",
                reportedContentId: "content456",
                reportedContentAuthorUid: "author789",
                category: .inappropriateContent,
                reason: "This content contains inappropriate language and imagery that violates community guidelines.",
                createdDate: Date(),
                status: .pending
            ))
        }
    }
}