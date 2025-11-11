public struct SIFRecipient: Codable, Identifiable {
    public var id: String
    public var name: String
    public var email: String
    public init(id: String = UUID().uuidString, name: String, email: String) {
        self.id = id; self.name = name; self.email = email
    }
}
