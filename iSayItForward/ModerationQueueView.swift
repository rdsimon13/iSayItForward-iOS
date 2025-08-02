import SwiftUI
import FirebaseFirestore

struct ModerationQueueView: View {
    @StateObject private var contentSafetyService = ContentSafetyService()
    @State private var reports: [ReportItem] = []
    @State private var isLoading = true
    @State private var selectedReport: ReportItem?
    @State private var showingModerationSheet = false
    
    var body: some View {
        ZStack {
            Color.mainAppGradient.ignoresSafeArea()
            
            VStack {
                if isLoading {
                    ProgressView("Loading reports...")
                        .foregroundColor(.white)
                } else if reports.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.shield")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("No Pending Reports")
                            .font(.title2.weight(.semibold))
                            .foregroundColor(.white)
                        
                        Text("All reports have been reviewed.")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                } else {
                    List {
                        ForEach(reports, id: \.id) { report in
                            ReportRowView(report: report) {
                                selectedReport = report
                                showingModerationSheet = true
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Moderation Queue")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        loadReports()
                    }
                }
            }
            .onAppear {
                loadReports()
            }
            .sheet(isPresented: $showingModerationSheet) {
                if let report = selectedReport {
                    ModerationDetailView(report: report) {
                        loadReports() // Refresh after moderation action
                    }
                }
            }
        }
    }
    
    private func loadReports() {
        isLoading = true
        
        Task {
            do {
                let pendingReports = try await contentSafetyService.getPendingReports()
                await MainActor.run {
                    self.reports = pendingReports
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    print("Error loading reports: \(error)")
                    self.isLoading = false
                }
            }
        }
    }
}

struct ReportRowView: View {
    let report: ReportItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(report.reason.displayName)
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    Spacer()
                    
                    Text(report.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let description = report.description, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    Text("Content ID: \(report.reportedContentId.prefix(8))...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("Reported by: \(report.reporterId.prefix(8))...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ModerationDetailView: View {
    let report: ReportItem
    let onComplete: () -> Void
    @StateObject private var contentSafetyService = ContentSafetyService()
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedAction: ModerationAction?
    @State private var moderatorNotes: String = ""
    @State private var isProcessing = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var contentPreview: String = "Loading content..."
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Report Details
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Report Details")
                            .font(.title2.weight(.bold))
                        
                        DetailRow(title: "Reason", value: report.reason.displayName)
                        DetailRow(title: "Reported", value: report.timestamp.formatted(date: .long, time: .shortened))
                        
                        if let description = report.description, !description.isEmpty {
                            DetailRow(title: "Description", value: description)
                        }
                    }
                    .padding()
                    .background(.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Content Preview
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reported Content")
                            .font(.headline)
                        
                        Text(contentPreview)
                            .font(.body)
                            .padding()
                            .background(.white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .padding()
                    .background(.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Moderation Actions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Moderation Action")
                            .font(.headline)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach([ModerationAction.noAction, .contentRemoved, .userWarned, .userSuspended], id: \.self) { action in
                                ActionSelectionCard(
                                    action: action,
                                    isSelected: selectedAction == action
                                ) {
                                    selectedAction = action
                                }
                            }
                        }
                    }
                    .padding()
                    .background(.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Moderator Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Moderator Notes")
                            .font(.headline)
                        
                        TextEditor(text: $moderatorNotes)
                            .frame(minHeight: 60)
                            .padding(8)
                            .background(.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .padding()
                    .background(.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Submit Button
                    Button(action: submitModerationAction) {
                        HStack {
                            if isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text(isProcessing ? "Processing..." : "Submit Decision")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedAction != nil ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(selectedAction == nil || isProcessing)
                    .padding(.horizontal)
                }
                .padding()
            }
            .background(Color.mainAppGradient.ignoresSafeArea())
            .foregroundColor(.white)
            .navigationTitle("Review Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadContentPreview()
            }
            .alert("Success", isPresented: $showingAlert) {
                Button("OK") {
                    onComplete()
                    dismiss()
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func loadContentPreview() {
        let db = Firestore.firestore()
        db.collection("sifs").document(report.reportedContentId).getDocument { snapshot, error in
            if let document = snapshot, document.exists,
               let data = document.data(),
               let subject = data["subject"] as? String,
               let message = data["message"] as? String {
                contentPreview = "Subject: \(subject)\n\nMessage: \(message)"
            } else {
                contentPreview = "Content not found or has been removed."
            }
        }
    }
    
    private func submitModerationAction() {
        guard let action = selectedAction else { return }
        
        isProcessing = true
        
        Task {
            do {
                // Update report status
                try await contentSafetyService.updateReportStatus(
                    reportId: report.id ?? "",
                    status: .resolved,
                    action: action,
                    moderatorNotes: moderatorNotes.isEmpty ? nil : moderatorNotes
                )
                
                // Take additional action if needed
                if action == .contentRemoved {
                    try await contentSafetyService.removeContent(report.reportedContentId)
                }
                
                await MainActor.run {
                    isProcessing = false
                    alertMessage = "Moderation action completed successfully."
                    showingAlert = true
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
        }
    }
}

struct ActionSelectionCard: View {
    let action: ModerationAction
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(action.displayName)
                .font(.subheadline.weight(.medium))
                .multilineTextAlignment(.center)
                .padding()
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color.blue : Color.white.opacity(0.1))
                .foregroundColor(isSelected ? .white : .white.opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.blue : Color.white.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            Text(value)
                .font(.body.weight(.medium))
        }
    }
}

struct ModerationQueueView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ModerationQueueView()
        }
    }
}