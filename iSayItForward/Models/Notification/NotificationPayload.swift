import Foundation

// MARK: - Notification Payload
struct NotificationPayload: Codable, Equatable {
    let sifId: String?
    let senderId: String?
    let templateId: String?
    let chatId: String?
    let deepLink: String?
    let metadata: [String: String]?
    
    init(
        sifId: String? = nil,
        senderId: String? = nil,
        templateId: String? = nil,
        chatId: String? = nil,
        deepLink: String? = nil,
        metadata: [String: String]? = nil
    ) {
        self.sifId = sifId
        self.senderId = senderId
        self.templateId = templateId
        self.chatId = chatId
        self.deepLink = deepLink
        self.metadata = metadata
    }
}

// MARK: - Payload Factory
extension NotificationPayload {
    static func sifPayload(sifId: String, senderId: String) -> NotificationPayload {
        return NotificationPayload(
            sifId: sifId,
            senderId: senderId,
            deepLink: "isayitforward://sif/\(sifId)"
        )
    }
    
    static func friendRequestPayload(senderId: String) -> NotificationPayload {
        return NotificationPayload(
            senderId: senderId,
            deepLink: "isayitforward://profile/\(senderId)"
        )
    }
    
    static func messagePayload(chatId: String, senderId: String) -> NotificationPayload {
        return NotificationPayload(
            senderId: senderId,
            chatId: chatId,
            deepLink: "isayitforward://chat/\(chatId)"
        )
    }
    
    static func templatePayload(templateId: String, senderId: String? = nil) -> NotificationPayload {
        return NotificationPayload(
            senderId: senderId,
            templateId: templateId,
            deepLink: "isayitforward://template/\(templateId)"
        )
    }
    
    static func achievementPayload(achievementId: String, metadata: [String: String]? = nil) -> NotificationPayload {
        return NotificationPayload(
            deepLink: "isayitforward://achievement/\(achievementId)",
            metadata: metadata
        )
    }
}