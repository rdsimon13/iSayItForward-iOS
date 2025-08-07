import Foundation
import FirebaseFirestore

// Enhanced data model for a SIF with comprehensive message creation features
struct SIFItem: Identifiable, Codable, Hashable, Equatable {
    // This property will automatically be managed by Firestore
    @DocumentID var id: String?
    
    let authorUid: String
    var recipients: [String]
    var subject: String
    var message: String
    let createdDate: Date
    var scheduledDate: Date
    
    // Enhanced properties for comprehensive message creation
    var attachmentURL: String? = nil
    var templateName: String? = nil
    var categoryTags: [String] = []
    var privacyLevel: String = "public" // public, friends, private
    var mediaAttachments: [MediaAttachment] = []
    var isScheduled: Bool = false
    var characterCount: Int { message.count }
    
    // Computed property for privacy level enum
    var privacy: MessageDraft.PrivacyLevel {
        MessageDraft.PrivacyLevel(rawValue: privacyLevel) ?? .public
    }
    
    // Hashable & Equatable conformance for SwiftUI lists
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: SIFItem, rhs: SIFItem) -> Bool {
        lhs.id == rhs.id
    }
    
    // Convenience initializer with default values
    init(authorUid: String, recipients: [String], subject: String, message: String, 
         createdDate: Date, scheduledDate: Date, attachmentURL: String? = nil, 
         templateName: String? = nil, categoryTags: [String] = [], 
         privacyLevel: String = "public", mediaAttachments: [MediaAttachment] = []) {
        self.authorUid = authorUid
        self.recipients = recipients
        self.subject = subject
        self.message = message
        self.createdDate = createdDate
        self.scheduledDate = scheduledDate
        self.attachmentURL = attachmentURL
        self.templateName = templateName
        self.categoryTags = categoryTags
        self.privacyLevel = privacyLevel
        self.mediaAttachments = mediaAttachments
        self.isScheduled = scheduledDate > Date()
    }
}
