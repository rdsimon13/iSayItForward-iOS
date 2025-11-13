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
    public var status: String  // e.g. "draft", "queued", "sent"

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
}

public extension SIF {
    /// Legacy convenience taking Bool + Date for scheduling.
    init(
        id: String = UUID().uuidString,
        senderUID: String,
        recipients: [SIFRecipient],
        subject: String? = nil,
        message: String,
        deliveryType: DeliveryType,
        isScheduled: Bool,
        scheduleDate: Date? = nil,
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
            scheduledAt: isScheduled ? scheduleDate : nil,
            createdAt: createdAt,
            status: status
        )
    }

    /// Labeled-but-permissive overload to satisfy unlabeled/nil-heavy legacy calls.
    init(
        id: String = UUID().uuidString,
        senderUID: String,
        recipients: [SIFRecipient],
        subject: String?,
        message: String,
        deliveryType: DeliveryType,
        scheduledAt: Date?,
        createdAt: Date,
        status: String
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
