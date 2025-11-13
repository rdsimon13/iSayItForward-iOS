import Foundation

public extension SIF {
    /// Canonical initializer used by views; avoids unlabeled/ambiguous overloads.
    init(
        id: String = UUID().uuidString,
        senderUID: String,
        recipients: [SIFRecipient],
        subject: String?,
        message: String,
        deliveryType: DeliveryType,
        scheduledAt: Date? = nil,
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
            scheduledAt: scheduledAt,
            createdAt: createdAt,
            status: status
        )
    }
}
