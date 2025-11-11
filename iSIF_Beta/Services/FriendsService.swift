import Foundation
import FirebaseAuth
import FirebaseFirestore

public protocol FriendsProviding {
    func fetchFriends() async throws -> [SIFRecipient]
}

public class FriendsService: FriendsProviding {
    public init() {}
    
    public func fetchFriends() async throws -> [SIFRecipient] {
        // Mock implementation - replace with actual Firestore query
        return [
            SIFRecipient(name: "John Doe", email: "john@example.com"),
            SIFRecipient(name: "Jane Smith", email: "jane@example.com"),
            SIFRecipient(name: "Bob Wilson", email: "bob@example.com")
        ]
    }
}
