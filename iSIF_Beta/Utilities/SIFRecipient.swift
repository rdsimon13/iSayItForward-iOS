import Foundation

public struct SIFRecipient: Codable, Identifiable, Hashable {
    public var id: String
    public var name: String
    public var email: String

    public init(id: String = UUID().uuidString, name: String, email: String) {
        self.id = id
        self.name = name
        self.email = email
    }
}
