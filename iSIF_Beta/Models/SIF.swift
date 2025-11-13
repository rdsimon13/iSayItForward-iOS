import Foundation

public struct SIF: Codable, Identifiable {
    public var id: String
    public var senderUID: String
    public var recipients: [SIFRecipient]
    public var subject: String?
    public var message: String
    public var deliveryType: DeliveryType
    public var scheduledAt: Date?
    public var createdAt: Date
    public var status: String
    public var signatureURL: URL?

    // ✅ Explicit public member-wise init INSIDE the struct.
    // This suppresses the synthesized one and avoids the redeclaration clash.
    public init(
        id: String = UUID().uuidString,
        senderUID: String,
        recipients: [SIFRecipient],
        subject: String? = nil,
        message: String,
        deliveryType: DeliveryType,
        scheduledAt: Date? = nil,
        createdAt: Date = Date(),
        status: String = "sent"
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
    }

    // ✅ Use consistent field names that match Firestore exactly
    enum CodingKeys: String, CodingKey {
        case id
        case senderUID
        case recipients
        case subject
        case message
        case deliveryType
        case scheduledAt
        case createdAt
        case status
        case signatureURL
    }
}

// ✅ Keep only this convenience overload in an extension.
public extension SIF {
    init(
        id: String = UUID().uuidString,
        senderUID: String,
        recipients: [SIFRecipient],
        subject: String? = nil,
        message: String,
        deliveryType: DeliveryType,
        isScheduled: Bool,
        scheduledDate: Date? = nil,
        createdAt: Date = Date(),
        status: String = "sent"
    ) {
        self.init(
            id: id,
            senderUID: senderUID,
            recipients: recipients,
            subject: subject,
            message: message,
            deliveryType: deliveryType,
            scheduledAt: isScheduled ? scheduledDate : nil,
            createdAt: createdAt,
            status: status
        )
    }
}
