import Foundation
import FirebaseFirestore

// MARK: - Sending Status Enums
enum SIFSendingStatus: String, Codable, CaseIterable {
    case draft = "draft"
    case scheduled = "scheduled"
    case uploading = "uploading"
    case sending = "sending"
    case sent = "sent"
    case failed = "failed"
    case cancelled = "cancelled"
}

enum SIFDeliveryStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case delivered = "delivered"
    case read = "read"
    case failed = "failed"
}

// This is the new, correct data model for a SIF.
// Codable allows it to be easily saved to and loaded from Firestore.
struct SIFItem: Identifiable, Codable, Hashable, Equatable {
    // This property will automatically be managed by Firestore
    @DocumentID var id: String?
    
    let authorUid: String
    var recipients: [String]
    var subject: String
    var message: String
    let createdDate: Date
    var scheduledDate: Date
    
    // These properties are placeholders for future features
    var attachmentURL: String? = nil
    var templateName: String? = nil
    
    // MARK: - Sending Status Properties
    var sendingStatus: SIFSendingStatus = .draft
    var deliveryStatus: SIFDeliveryStatus = .pending
    var uploadProgress: Double = 0.0
    var errorMessage: String? = nil
    var retryCount: Int = 0
    var lastRetryDate: Date? = nil
    var isScheduled: Bool = false
    
    // MARK: - Large File Properties
    var hasLargeAttachment: Bool = false
    var attachmentSize: Int64? = nil
    var chunkUploadProgress: [String: Double] = [:]
    
    // Hashable & Equatable conformance for SwiftUI lists
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: SIFItem, rhs: SIFItem) -> Bool {
        lhs.id == rhs.id
    }
    
    // MARK: - Computed Properties
    var canRetry: Bool {
        return sendingStatus == .failed && retryCount < 3
    }
    
    var isInProgress: Bool {
        return sendingStatus == .uploading || sendingStatus == .sending
    }
    
    var statusDisplayText: String {
        switch sendingStatus {
        case .draft:
            return "Draft"
        case .scheduled:
            return "Scheduled"
        case .uploading:
            return "Uploading..."
        case .sending:
            return "Sending..."
        case .sent:
            return "Sent"
        case .failed:
            return "Failed"
        case .cancelled:
            return "Cancelled"
        }
    }
}
