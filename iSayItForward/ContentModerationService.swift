import Foundation
import FirebaseFirestore
import FirebaseAuth

/// Service specifically for content moderation operations
@MainActor
class ContentModerationService: ObservableObject {
    private let db = Firestore.firestore()
    private let contentSafetyService = ContentSafetyService()
    
    @Published var pendingReportsCount: Int = 0
    @Published var isLoading = false
    
    // MARK: - Moderation Queue Management
    
    /// Get all pending reports for moderation
    func getPendingReports() async throws -> [ReportItem] {
        return try await contentSafetyService.getPendingReports()
    }
    
    /// Get reports filtered by status
    func getReportsByStatus(_ status: ReportStatus) async throws -> [ReportItem] {
        let snapshot = try await db.collection("reports")
            .whereField("status", isEqualTo: status.rawValue)
            .order(by: "timestamp", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: ReportItem.self)
        }
    }
    
    /// Update pending reports count
    func updatePendingReportsCount() async {
        do {
            let reports = try await getPendingReports()
            pendingReportsCount = reports.count
        } catch {
            print("Error updating pending reports count: \(error)")
            pendingReportsCount = 0
        }
    }
    
    /// Take moderation action on a report
    func moderateReport(
        reportId: String,
        action: ModerationAction,
        notes: String? = nil
    ) async throws {
        // Update report status
        try await contentSafetyService.updateReportStatus(
            reportId: reportId,
            status: .resolved,
            action: action,
            moderatorNotes: notes
        )
        
        // Execute the moderation action
        let report = try await getReport(reportId)
        try await executeAction(action, for: report)
        
        // Update pending count
        await updatePendingReportsCount()
    }
    
    /// Get a specific report by ID
    private func getReport(_ reportId: String) async throws -> ReportItem {
        let doc = try await db.collection("reports").document(reportId).getDocument()
        guard let report = try? doc.data(as: ReportItem.self) else {
            throw ContentSafetyError.contentNotFound
        }
        return report
    }
    
    /// Execute specific moderation action
    private func executeAction(_ action: ModerationAction, for report: ReportItem) async throws {
        switch action {
        case .contentRemoved:
            try await contentSafetyService.removeContent(report.reportedContentId)
            
        case .userWarned:
            try await sendUserWarning(userId: report.reportedUserId, reason: report.reason)
            
        case .userSuspended:
            try await suspendUser(userId: report.reportedUserId, duration: .days(7))
            
        case .userBanned:
            try await banUser(userId: report.reportedUserId)
            
        case .noAction:
            // No additional action needed
            break
        }
    }
    
    // MARK: - User Management Actions
    
    /// Send warning to user
    private func sendUserWarning(userId: String, reason: ReportReason) async throws {
        let warning = UserWarning(
            userId: userId,
            reason: reason,
            timestamp: Date(),
            issuedBy: Auth.auth().currentUser?.uid ?? ""
        )
        
        try await db.collection("user_warnings").addDocument(from: warning)
    }
    
    /// Suspend user account
    private func suspendUser(userId: String, duration: TimeInterval) async throws {
        let suspension = UserSuspension(
            userId: userId,
            startDate: Date(),
            endDate: Date().addingTimeInterval(duration),
            issuedBy: Auth.auth().currentUser?.uid ?? ""
        )
        
        try await db.collection("user_suspensions").addDocument(from: suspension)
        try await db.collection("users").document(userId).updateData([
            "isSuspended": true,
            "suspensionEndDate": suspension.endDate
        ])
    }
    
    /// Ban user account permanently
    private func banUser(userId: String) async throws {
        try await db.collection("users").document(userId).updateData([
            "isBanned": true,
            "bannedDate": Date(),
            "bannedBy": Auth.auth().currentUser?.uid ?? ""
        ])
    }
    
    // MARK: - Analytics and Reporting
    
    /// Get moderation statistics
    func getModerationStats() async throws -> ModerationStats {
        let allReports = try await db.collection("reports").getDocuments()
        
        var stats = ModerationStats()
        
        for doc in allReports.documents {
            guard let report = try? doc.data(as: ReportItem.self) else { continue }
            
            stats.totalReports += 1
            
            switch report.status {
            case .pending:
                stats.pendingReports += 1
            case .resolved:
                stats.resolvedReports += 1
            case .dismissed:
                stats.dismissedReports += 1
            case .underReview:
                stats.underReviewReports += 1
            }
            
            stats.reportsByReason[report.reason, default: 0] += 1
            
            if let action = report.actionTaken {
                stats.actionsTaken[action, default: 0] += 1
            }
        }
        
        return stats
    }
}

// MARK: - Supporting Models

struct UserWarning: Codable {
    let userId: String
    let reason: ReportReason
    let timestamp: Date
    let issuedBy: String
}

struct UserSuspension: Codable {
    let userId: String
    let startDate: Date
    let endDate: Date
    let issuedBy: String
}

struct ModerationStats {
    var totalReports: Int = 0
    var pendingReports: Int = 0
    var resolvedReports: Int = 0
    var dismissedReports: Int = 0
    var underReviewReports: Int = 0
    var reportsByReason: [ReportReason: Int] = [:]
    var actionsTaken: [ModerationAction: Int] = [:]
}

extension TimeInterval {
    static func days(_ days: Int) -> TimeInterval {
        return TimeInterval(days * 24 * 60 * 60)
    }
    
    static func hours(_ hours: Int) -> TimeInterval {
        return TimeInterval(hours * 60 * 60)
    }
}