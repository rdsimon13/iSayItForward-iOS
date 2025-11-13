import Foundation
import FirebaseFirestoreSwift

public struct SIF: Codable, Identifiable {
    @DocumentID public var id: String?
    public var senderUID: String
    public var recipients: [SIFRecipient]
    public var subject: String?
    public var message: String
    public var deliveryType: DeliveryType
    public var scheduledAt: Date?
    public var createdAt: Date
    public var status: String
    public var signatureURL: URL?

    public init(
        id: String? = nil,
        senderUID: String,
        recipients: [SIFRecipient],
        subject: String? = nil,
        message: String,
        deliveryType: DeliveryType,
        scheduledAt: Date? = nil,
        createdAt: Date = Date(),
        status: String = "sent",
        signatureURL: URL? = nil
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
        self.signatureURL = signatureURL
    }
}
