import Foundation
import FirebaseFirestore

// Enhanced SIF data model with delivery tracking and content management
struct SIFItem: Identifiable, Codable, Hashable, Equatable {
    // This property will automatically be managed by Firestore
    @DocumentID var id: String?
    
    let authorUid: String
    var recipients: [String]
    var subject: String
    var message: String
    let createdDate: Date
    var scheduledDate: Date
    
    // Delivery and Status Management
    var deliveryStatus: SIFDeliveryStatus = .pending
    var deliveredDate: Date? = nil
    var retryCount: Int = 0
    var lastRetryDate: Date? = nil
    var progressPercentage: Double = 0.0
    var failureReason: String? = nil
    
    // Content Management
    var attachmentURLs: [String] = []
    var attachmentTypes: [String] = [] // file extensions or MIME types
    var attachmentSizes: [Int64] = [] // file sizes in bytes
    var totalAttachmentSize: Int64 = 0
    var templateName: String? = nil
    
    // QR Code and Sharing
    var qrCodeData: String? = nil
    var qrCodeImageURL: String? = nil
    var shareableLink: String? = nil
    
    // Management Features
    var folderPath: String = "sent" // default folder
    var tags: [String] = []
    var isFavorite: Bool = false
    var isArchived: Bool = false
    
    // Expiration and Control
    var expirationDate: Date? = nil
    var canExtendExpiration: Bool = true
    var isCancelled: Bool = false
    var cancelledDate: Date? = nil
    
    // Notification Settings
    var notifyOnDelivery: Bool = true
    var notifyOnOpen: Bool = false
    var deliveryNotificationSent: Bool = false
    
    // Hashable & Equatable conformance for SwiftUI lists
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: SIFItem, rhs: SIFItem) -> Bool {
        lhs.id == rhs.id
    }
}

// Delivery status enumeration
enum SIFDeliveryStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case scheduled = "scheduled" 
    case processing = "processing"
    case uploading = "uploading"
    case delivered = "delivered"
    case failed = "failed"
    case cancelled = "cancelled"
    case expired = "expired"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .scheduled: return "Scheduled"
        case .processing: return "Processing"
        case .uploading: return "Uploading"
        case .delivered: return "Delivered"
        case .failed: return "Failed"
        case .cancelled: return "Cancelled"
        case .expired: return "Expired"
        }
    }
    
    var systemImageName: String {
        switch self {
        case .pending: return "clock"
        case .scheduled: return "calendar"
        case .processing: return "gearshape"
        case .uploading: return "arrow.up.circle"
        case .delivered: return "checkmark.circle"
        case .failed: return "xmark.circle"
        case .cancelled: return "stop.circle"
        case .expired: return "hourglass"
        }
    }
}
