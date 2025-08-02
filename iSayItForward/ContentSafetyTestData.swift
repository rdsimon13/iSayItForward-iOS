import Foundation

/// Test data and utility functions for demonstrating Content Safety features
/// This file is for development and testing purposes only
struct ContentSafetyTestData {
    
    // MARK: - Sample Reports
    static let sampleReports: [Report] = [
        Report(
            reporterUid: "user123",
            reportedContentId: "content456",
            reportedContentAuthorUid: "author789",
            category: .inappropriateContent,
            reason: "This content contains inappropriate language and imagery that violates community guidelines.",
            createdDate: Date().addingTimeInterval(-86400 * 2), // 2 days ago
            status: .pending
        ),
        Report(
            reporterUid: "user456",
            reportedContentId: "content789",
            reportedContentAuthorUid: "author123",
            category: .spam,
            reason: "This user is repeatedly posting the same promotional content.",
            createdDate: Date().addingTimeInterval(-86400), // 1 day ago
            status: .underReview,
            moderatorUid: "mod123",
            moderatorNotes: "Investigating user's posting history.",
            reviewedDate: Date().addingTimeInterval(-3600) // 1 hour ago
        ),
        Report(
            reporterUid: "user789",
            reportedContentId: "content123",
            reportedContentAuthorUid: "author456",
            category: .harassment,
            reason: "User is sending threatening messages and harassing other community members.",
            createdDate: Date().addingTimeInterval(-86400 * 3), // 3 days ago
            status: .resolved,
            moderatorUid: "mod456",
            moderatorNotes: "Content removed and user warned. Account will be monitored.",
            reviewedDate: Date().addingTimeInterval(-86400) // 1 day ago
        )
    ]
    
    // MARK: - Sample Blocked Users
    static let sampleBlockedUsers: [BlockedUser] = [
        BlockedUser(
            blockerUid: "currentUser",
            blockedUid: "spammer123",
            blockedDate: Date().addingTimeInterval(-86400 * 5), // 5 days ago
            reason: "Repeatedly sending spam messages"
        ),
        BlockedUser(
            blockerUid: "currentUser",
            blockedUid: "troll456",
            blockedDate: Date().addingTimeInterval(-86400 * 10), // 10 days ago
            reason: "Harassment and inappropriate behavior"
        )
    ]
    
    // MARK: - Sample SIF Items for Testing
    static let sampleSIFItems: [SIFItem] = [
        SIFItem(
            authorUid: "user123",
            recipients: ["friend@example.com"],
            subject: "Happy Birthday!",
            message: "Hope you have a wonderful day filled with joy and celebration!",
            createdDate: Date().addingTimeInterval(-3600),
            scheduledDate: Date().addingTimeInterval(86400)
        ),
        SIFItem(
            authorUid: "spammer123", // This user is blocked
            recipients: ["victim@example.com"],
            subject: "Buy Now!",
            message: "Get rich quick with this amazing opportunity! Click here now!",
            createdDate: Date().addingTimeInterval(-7200),
            scheduledDate: Date().addingTimeInterval(172800)
        ),
        SIFItem(
            authorUid: "user456",
            recipients: ["colleague@work.com"],
            subject: "Meeting Reminder",
            message: "Don't forget about our meeting tomorrow at 2 PM.",
            createdDate: Date().addingTimeInterval(-1800),
            scheduledDate: Date().addingTimeInterval(43200)
        )
    ]
    
    // MARK: - Demo Scenarios
    
    /// Demonstrates content filtering - removes content from blocked users
    static func getFilteredContent() -> [SIFItem] {
        let blockedUserUids = Set(sampleBlockedUsers.map { $0.blockedUid })
        return sampleSIFItems.filter { !blockedUserUids.contains($0.authorUid) }
    }
    
    /// Get reports by status for moderator view
    static func getReportsByStatus(_ status: ReportStatus) -> [Report] {
        return sampleReports.filter { $0.status == status }
    }
    
    /// Simulate report categories distribution
    static func getReportCategoryDistribution() -> [ReportCategory: Int] {
        var distribution: [ReportCategory: Int] = [:]
        for report in sampleReports {
            distribution[report.category, default: 0] += 1
        }
        return distribution
    }
}

// MARK: - Development Helpers

#if DEBUG
extension ContentSafetyTestData {
    
    /// Print sample data for debugging
    static func printSampleData() {
        print("=== Content Safety Test Data ===")
        print("Sample Reports: \(sampleReports.count)")
        print("Sample Blocked Users: \(sampleBlockedUsers.count)")
        print("Sample SIF Items: \(sampleSIFItems.count)")
        print("Filtered SIF Items: \(getFilteredContent().count)")
        print("Report Category Distribution: \(getReportCategoryDistribution())")
    }
    
    /// Create a report with current timestamp
    static func createTestReport(category: ReportCategory = .spam) -> Report {
        return Report(
            reporterUid: "testUser",
            reportedContentId: "testContent\(UUID().uuidString.prefix(8))",
            reportedContentAuthorUid: "testAuthor",
            category: category,
            reason: "Test report created at \(Date())",
            createdDate: Date(),
            status: .pending
        )
    }
}
#endif