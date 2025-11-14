import Foundation
import FirebaseFirestore

public struct SIF: Codable, Identifiable, Hashable {
    public var id: String
    public var senderUID: String
    public var recipients: [SIFRecipient]
    public var subject: String?
    public var message: String
    public var deliveryType: String          // "oneToOne", "oneToMany", "group"
    public var deliveryChannel: String       // "inApp", "email", "sms"
    public var deliveryDate: Date?
    public var createdAt: Date
    public var status: String
    public var signatureURLString: String?   // Firestore-safe URL
    public var attachments: [String]?        // Array of attachment URLs
    public var templateName: String?         // Template identifier
    public var textOverlay: String?          // Text overlay content

    // MARK: - Computed property for optional URL
    public var signatureURL: URL? {
        guard let signatureURLString = signatureURLString else { return nil }
        return URL(string: signatureURLString)
    }

    // MARK: - Main Initializer
    public init(
        id: String = UUID().uuidString,
        senderUID: String,
        recipients: [SIFRecipient],
        subject: String? = nil,
        message: String,
        deliveryType: String,
        deliveryChannel: String = "inApp",
        deliveryDate: Date? = nil,
        createdAt: Date = Date(),
        status: String = "sent",
        signatureURLString: String? = nil,
        attachments: [String]? = nil,
        templateName: String? = nil,
        textOverlay: String? = nil
    ) {
        self.id = id
        self.senderUID = senderUID
        self.recipients = recipients
        self.subject = subject
        self.message = message
        self.deliveryType = deliveryType
        self.deliveryChannel = deliveryChannel
        self.deliveryDate = deliveryDate
        self.createdAt = createdAt
        self.status = status
        self.signatureURLString = signatureURLString
        self.attachments = attachments
        self.templateName = templateName
        self.textOverlay = textOverlay
    }

    // MARK: - Firestore Codable Keys
    enum CodingKeys: String, CodingKey {
        case id, senderUID, recipients, subject, message,
             deliveryType, deliveryChannel, deliveryDate, createdAt, status, 
             signatureURLString, attachments, templateName, textOverlay
    }
}
