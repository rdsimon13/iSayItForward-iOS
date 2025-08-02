import Foundation
import FirebaseFirestore
import FirebaseAuth

/// Service for handling content safety features including reporting and moderation
@MainActor
class ContentSafetyService: ObservableObject {
    private let db = Firestore.firestore()
    
    // MARK: - Content Reporting
    
    /// Submit a report for a piece of content
    func reportContent(
        contentId: String,
        contentAuthorId: String,
        reason: ReportReason,
        description: String? = nil
    ) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw ContentSafetyError.userNotAuthenticated
        }
        
        // Prevent users from reporting their own content
        if currentUserId == contentAuthorId {
            throw ContentSafetyError.cannotReportOwnContent
        }
        
        // Check if user has already reported this content
        let existingReport = try await checkExistingReport(
            reporterId: currentUserId,
            contentId: contentId
        )
        
        if existingReport != nil {
            throw ContentSafetyError.alreadyReported
        }
        
        let report = ReportItem(
            reporterId: currentUserId,
            reportedContentId: contentId,
            reportedUserId: contentAuthorId,
            reason: reason,
            description: description,
            timestamp: Date(),
            status: .pending
        )
        
        try await db.collection("reports").addDocument(from: report)
    }
    
    /// Check if a user has already reported specific content
    private func checkExistingReport(reporterId: String, contentId: String) async throws -> ReportItem? {
        let snapshot = try await db.collection("reports")
            .whereField("reporterId", isEqualTo: reporterId)
            .whereField("reportedContentId", isEqualTo: contentId)
            .getDocuments()
        
        return snapshot.documents.first?.data(as: ReportItem.self)
    }
    
    /// Get all reports for a specific piece of content
    func getReportsForContent(_ contentId: String) async throws -> [ReportItem] {
        let snapshot = try await db.collection("reports")
            .whereField("reportedContentId", isEqualTo: contentId)
            .order(by: "timestamp", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: ReportItem.self)
        }
    }
    
    /// Get all pending reports (for moderation)
    func getPendingReports() async throws -> [ReportItem] {
        let snapshot = try await db.collection("reports")
            .whereField("status", isEqualTo: ReportStatus.pending.rawValue)
            .order(by: "timestamp", descending: false)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: ReportItem.self)
        }
    }
    
    // MARK: - Moderation Actions
    
    /// Update the status of a report (for moderators)
    func updateReportStatus(
        reportId: String,
        status: ReportStatus,
        action: ModerationAction? = nil,
        moderatorNotes: String? = nil
    ) async throws {
        guard let moderatorId = Auth.auth().currentUser?.uid else {
            throw ContentSafetyError.userNotAuthenticated
        }
        
        var updateData: [String: Any] = [
            "status": status.rawValue,
            "moderatorId": moderatorId,
            "resolvedDate": Date()
        ]
        
        if let action = action {
            updateData["actionTaken"] = action.rawValue
        }
        
        if let notes = moderatorNotes {
            updateData["moderatorNotes"] = notes
        }
        
        try await db.collection("reports").document(reportId).updateData(updateData)
    }
    
    /// Remove content (for moderators)
    func removeContent(_ contentId: String) async throws {
        // Mark content as removed
        try await db.collection("sifs").document(contentId).updateData([
            "isRemoved": true,
            "removedDate": Date(),
            "removedBy": Auth.auth().currentUser?.uid ?? ""
        ])
    }
    
    // MARK: - Content Filtering
    
    /// Check if content should be hidden from a user (due to reports or moderation)
    func shouldHideContent(_ contentId: String, from userId: String) async throws -> Bool {
        // Check if content has been removed
        let contentDoc = try await db.collection("sifs").document(contentId).getDocument()
        if let isRemoved = contentDoc.data()?["isRemoved"] as? Bool, isRemoved {
            return true
        }
        
        // Check if user has reported this content
        let userReport = try await checkExistingReport(reporterId: userId, contentId: contentId)
        return userReport != nil
    }
    
    /// Get report statistics for content
    func getContentReportStats(_ contentId: String) async throws -> ContentReportStats {
        let reports = try await getReportsForContent(contentId)
        
        var reasonCounts: [ReportReason: Int] = [:]
        for report in reports {
            reasonCounts[report.reason, default: 0] += 1
        }
        
        return ContentReportStats(
            totalReports: reports.count,
            pendingReports: reports.filter { $0.status == .pending }.count,
            reasonBreakdown: reasonCounts,
            mostRecentReport: reports.first?.timestamp
        )
    }
}

// MARK: - Supporting Types

struct ContentReportStats {
    let totalReports: Int
    let pendingReports: Int
    let reasonBreakdown: [ReportReason: Int]
    let mostRecentReport: Date?
}

enum ContentSafetyError: LocalizedError {
    case userNotAuthenticated
    case cannotReportOwnContent
    case alreadyReported
    case contentNotFound
    case insufficientPermissions
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "You must be signed in to perform this action."
        case .cannotReportOwnContent:
            return "You cannot report your own content."
        case .alreadyReported:
            return "You have already reported this content."
        case .contentNotFound:
            return "The content you're trying to report was not found."
        case .insufficientPermissions:
            return "You don't have permission to perform this action."
        }
    }
}