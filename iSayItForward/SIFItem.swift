import Foundation
import FirebaseFirestore

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
    
    // Attachment support
    var attachments: [Attachment] = []
    
    // These properties are placeholders for future features
    var attachmentURL: String? = nil // Legacy field - kept for backward compatibility
    var templateName: String? = nil
    
    // Custom initializer to support attachments
    init(authorUid: String, recipients: [String], subject: String, message: String, 
         createdDate: Date, scheduledDate: Date, attachments: [Attachment] = []) {
        self.authorUid = authorUid
        self.recipients = recipients
        self.subject = subject
        self.message = message
        self.createdDate = createdDate
        self.scheduledDate = scheduledDate
        self.attachments = attachments
    }
    
    // Hashable & Equatable conformance for SwiftUI lists
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: SIFItem, rhs: SIFItem) -> Bool {
        lhs.id == rhs.id
    }
}
