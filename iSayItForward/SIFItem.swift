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
    
    // These properties are placeholders for future features
    var attachmentURL: String? = nil
    var templateName: String? = nil
    
    // Categories and Tags system
    var categoryIds: [String] = []
    var tags: [String] = []
    
    // Hashable & Equatable conformance for SwiftUI lists
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: SIFItem, rhs: SIFItem) -> Bool {
        lhs.id == rhs.id
    }
}
