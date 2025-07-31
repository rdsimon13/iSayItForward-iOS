import Foundation
import FirebaseFirestore

// This is the new, correct data model for a SIF.
// Codable allows it to be easily saved to and loaded from Firestore.
struct SIFItem: Identifiable, Codable, Hashable, Equatable {
    // This property will automatically be managed by Firestore
    @DocumentID var id: String?
    
    var authorUid: String
    var recipients: [String]
    var subject: String
    var message: String
    let createdDate: Date
    var scheduledDate: Date
    
    // Attachment support
    var attachmentURL: String? = nil
    var attachmentURLs: [String]? = nil
    var templateName: String? = nil
    
    // Privacy controls
    var isPrivate: Bool = false
    var allowForwarding: Bool = true
    var requireReadReceipt: Bool = false
    
    // Hashable & Equatable conformance for SwiftUI lists
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: SIFItem, rhs: SIFItem) -> Bool {
        lhs.id == rhs.id
    }
}
