import Foundation
import FirebaseFirestore

public struct SIF: Codable, Identifiable, Hashable {
    public var id: String
    public var senderUID: String
    public var recipients: [SIFRecipient]
    public var subject: String?
    public var message: String
    public var deliveryType: String          // ✅ Firestore-safe String
    public var scheduledAt: Date?
    public var createdAt: Date
    public var status: String
    public var signatureURLString: String?   // ✅ Firestore-safe URL

    // MARK: - Computed property for optional URL
    public var signatureURL: URL? {
        guard let signatureURLString = signatureURLString else { return nil }
        return URL(string: signatureURLString)
    }

    // MARK: - Main Initializer (✅ single source of truth)
    public init(
        id: String = UUID().uuidString,
        senderUID: String,
        recipients: [SIFRecipient],
        subject: String? = nil,
        message: String,
        deliveryType: String,
        scheduledAt: Date? = nil,
        createdAt: Date = Date(),
        status: String = "sent",
        signatureURLString: String? = nil
    ) {
        self.id = id
        self.senderUID = senderUID
        self.recipients = recipients
        self.subject = subject
        self.message = message
        self.deliveryType = deliveryType
        self.scheduledAt = scheduledAt
        self.createdAt = createdAt
        self.status = status
        self.signatureURLString = signatureURLString
    }

    // MARK: - Firestore Codable Keys
    enum CodingKeys: String, CodingKey {
        case id, senderUID, recipients, subject, message,
             deliveryType, scheduledAt, createdAt, status, signatureURLString
    }
}
