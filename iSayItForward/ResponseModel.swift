import Foundation
import FirebaseFirestore

/// Model for storing response data
struct ResponseModel: Identifiable, Codable, Hashable, Equatable {
    @DocumentID var id: String?
    
    let authorUid: String
    let originalSIFId: String
    let responseText: String
    let createdDate: Date
    let category: ResponseCategory
    let privacyLevel: PrivacyLevel
    let impactScore: Double?
    
    // eSignature information
    let signatureId: String?
    let requiresSignature: Bool
    let isSignatureValid: Bool
    
    // Validation and metadata
    let isValidated: Bool
    let validationDate: Date?
    let attachmentURL: String?
    
    init(authorUid: String, originalSIFId: String, responseText: String, category: ResponseCategory, privacyLevel: PrivacyLevel = .public, requiresSignature: Bool = false, signatureId: String? = nil) {
        self.authorUid = authorUid
        self.originalSIFId = originalSIFId
        self.responseText = responseText
        self.createdDate = Date()
        self.category = category
        self.privacyLevel = privacyLevel
        self.requiresSignature = requiresSignature
        self.signatureId = signatureId
        self.isSignatureValid = signatureId != nil
        self.impactScore = nil
        self.isValidated = false
        self.validationDate = nil
        self.attachmentURL = nil
    }
    
    // Hashable & Equatable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ResponseModel, rhs: ResponseModel) -> Bool {
        lhs.id == rhs.id
    }
}

/// Categories for response classification
enum ResponseCategory: String, Codable, CaseIterable {
    case gratitude = "gratitude"
    case feedback = "feedback"
    case request = "request"
    case acknowledgment = "acknowledgment"
    case question = "question"
    case suggestion = "suggestion"
    case compliment = "compliment"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .gratitude:
            return "Gratitude"
        case .feedback:
            return "Feedback"
        case .request:
            return "Request"
        case .acknowledgment:
            return "Acknowledgment"
        case .question:
            return "Question"
        case .suggestion:
            return "Suggestion"
        case .compliment:
            return "Compliment"
        case .other:
            return "Other"
        }
    }
    
    var iconName: String {
        switch self {
        case .gratitude:
            return "heart.fill"
        case .feedback:
            return "bubble.left.and.bubble.right"
        case .request:
            return "hand.raised"
        case .acknowledgment:
            return "checkmark.circle"
        case .question:
            return "questionmark.circle"
        case .suggestion:
            return "lightbulb"
        case .compliment:
            return "star.fill"
        case .other:
            return "ellipsis.circle"
        }
    }
}

/// Privacy levels for responses
enum PrivacyLevel: String, Codable, CaseIterable {
    case `public` = "public"
    case `private` = "private"
    case restricted = "restricted"
    case anonymous = "anonymous"
    
    var displayName: String {
        switch self {
        case .public:
            return "Public"
        case .private:
            return "Private"
        case .restricted:
            return "Restricted"
        case .anonymous:
            return "Anonymous"
        }
    }
    
    var description: String {
        switch self {
        case .public:
            return "Visible to everyone"
        case .private:
            return "Only visible to you and the original sender"
        case .restricted:
            return "Visible to authorized users only"
        case .anonymous:
            return "Response is anonymous"
        }
    }
}