import Foundation
import FirebaseAuth
import FirebaseFirestore

/// Manages content safety operations including reporting, moderation, and user blocking
@MainActor
class ContentSafetyManager: ObservableObject {
    private let db = Firestore.firestore()
    
    @Published var reports: [Report] = []
    @Published var blockedUsers: [BlockedUser] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Report Management
    
    /// Submit a new report for content
    func submitReport(
        contentId: String,
        contentAuthorUid: String,
        category: ReportCategory,
        reason: String
    ) async throws {
        guard let currentUserUid = Auth.auth().currentUser?.uid else {
            throw ContentSafetyError.notAuthenticated
        }
        
        let report = Report(
            reporterUid: currentUserUid,
            reportedContentId: contentId,
            reportedContentAuthorUid: contentAuthorUid,
            category: category,
            reason: reason,
            createdDate: Date(),
            status: .pending
        )
        
        do {
            _ = try db.collection("reports").addDocument(from: report)
        } catch {
            throw ContentSafetyError.failedToSubmitReport(error.localizedDescription)
        }
    }
    
    /// Fetch all reports (for moderators)
    func fetchReports() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let snapshot = try await db.collection("reports")
                .order(by: "createdDate", descending: true)
                .getDocuments()
            
            let fetchedReports = try snapshot.documents.compactMap { document in
                try document.data(as: Report.self)
            }
            
            await MainActor.run {
                self.reports = fetchedReports
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to fetch reports: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    /// Update report status (for moderators)
    func updateReportStatus(
        reportId: String,
        status: ReportStatus,
        moderatorNotes: String? = nil
    ) async throws {
        guard let currentUserUid = Auth.auth().currentUser?.uid else {
            throw ContentSafetyError.notAuthenticated
        }
        
        var updateData: [String: Any] = [
            "status": status.rawValue,
            "moderatorUid": currentUserUid,
            "reviewedDate": Date()
        ]
        
        if let notes = moderatorNotes {
            updateData["moderatorNotes"] = notes
        }
        
        do {
            try await db.collection("reports").document(reportId).updateData(updateData)
            
            // Record moderator action
            let action = ModeratorAction(
                moderatorUid: currentUserUid,
                reportId: reportId,
                action: status.rawValue,
                notes: moderatorNotes,
                actionDate: Date()
            )
            
            _ = try db.collection("moderatorActions").addDocument(from: action)
            
            // Refresh reports
            await fetchReports()
        } catch {
            throw ContentSafetyError.failedToUpdateReport(error.localizedDescription)
        }
    }
    
    // MARK: - User Blocking Management
    
    /// Block a user
    func blockUser(userUid: String, reason: String? = nil) async throws {
        guard let currentUserUid = Auth.auth().currentUser?.uid else {
            throw ContentSafetyError.notAuthenticated
        }
        
        guard userUid != currentUserUid else {
            throw ContentSafetyError.cannotBlockSelf
        }
        
        let blockedUser = BlockedUser(
            blockerUid: currentUserUid,
            blockedUid: userUid,
            blockedDate: Date(),
            reason: reason
        )
        
        do {
            _ = try db.collection("blockedUsers").addDocument(from: blockedUser)
            
            // Update user's blocked users array
            try await db.collection("users").document(currentUserUid).updateData([
                "blockedUsers": FieldValue.arrayUnion([userUid])
            ])
            
            await fetchBlockedUsers()
        } catch {
            throw ContentSafetyError.failedToBlockUser(error.localizedDescription)
        }
    }
    
    /// Unblock a user
    func unblockUser(userUid: String) async throws {
        guard let currentUserUid = Auth.auth().currentUser?.uid else {
            throw ContentSafetyError.notAuthenticated
        }
        
        do {
            // Find and delete the blocked user record
            let snapshot = try await db.collection("blockedUsers")
                .whereField("blockerUid", isEqualTo: currentUserUid)
                .whereField("blockedUid", isEqualTo: userUid)
                .getDocuments()
            
            for document in snapshot.documents {
                try await document.reference.delete()
            }
            
            // Update user's blocked users array
            try await db.collection("users").document(currentUserUid).updateData([
                "blockedUsers": FieldValue.arrayRemove([userUid])
            ])
            
            await fetchBlockedUsers()
        } catch {
            throw ContentSafetyError.failedToUnblockUser(error.localizedDescription)
        }
    }
    
    /// Fetch blocked users for current user
    func fetchBlockedUsers() async {
        guard let currentUserUid = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let snapshot = try await db.collection("blockedUsers")
                .whereField("blockerUid", isEqualTo: currentUserUid)
                .order(by: "blockedDate", descending: true)
                .getDocuments()
            
            let fetchedBlockedUsers = try snapshot.documents.compactMap { document in
                try document.data(as: BlockedUser.self)
            }
            
            await MainActor.run {
                self.blockedUsers = fetchedBlockedUsers
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to fetch blocked users: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    /// Check if a user is blocked
    func isUserBlocked(_ userUid: String) -> Bool {
        return blockedUsers.contains { $0.blockedUid == userUid }
    }
    
    // MARK: - Content Filtering
    
    /// Filter SIF items to exclude content from blocked users
    func filterContent(_ sifItems: [SIFItem]) -> [SIFItem] {
        let blockedUserUids = Set(blockedUsers.map { $0.blockedUid })
        return sifItems.filter { !blockedUserUids.contains($0.authorUid) }
    }
    
    // MARK: - Moderator Permissions
    
    /// Check if current user is a moderator
    func checkModeratorStatus() async -> Bool {
        guard let currentUserUid = Auth.auth().currentUser?.uid else { return false }
        
        do {
            let document = try await db.collection("users").document(currentUserUid).getDocument()
            return document.data()?["isModerator"] as? Bool ?? false
        } catch {
            return false
        }
    }
}

// MARK: - Error Types

enum ContentSafetyError: LocalizedError {
    case notAuthenticated
    case failedToSubmitReport(String)
    case failedToUpdateReport(String)
    case failedToBlockUser(String)
    case failedToUnblockUser(String)
    case cannotBlockSelf
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be logged in to perform this action."
        case .failedToSubmitReport(let message):
            return "Failed to submit report: \(message)"
        case .failedToUpdateReport(let message):
            return "Failed to update report: \(message)"
        case .failedToBlockUser(let message):
            return "Failed to block user: \(message)"
        case .failedToUnblockUser(let message):
            return "Failed to unblock user: \(message)"
        case .cannotBlockSelf:
            return "You cannot block yourself."
        }
    }
}