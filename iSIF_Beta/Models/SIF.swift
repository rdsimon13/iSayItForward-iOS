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
    
    public init(
        id: String = UUID().uuidString,
        senderUID: String,
        recipients: [SIFRecipient],
        subject: String? = nil,
        message: String,
        deliveryType: DeliveryType,
        scheduledAt: Date? = nil,
        createdAt: Date = Date(),
        status: String = "queued"
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
