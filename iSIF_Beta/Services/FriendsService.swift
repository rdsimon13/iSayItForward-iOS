import Foundation

public protocol FriendsProviding {
    func fetchFriends() async throws -> [SIFRecipient]
}

public final class FriendService: FriendsProviding {
    public init() {}
    public func fetchFriends() async throws -> [SIFRecipient] {
        // Mock data; replace with Firestore later
        return [
            SIFRecipient(name: "Demo User", email: "demo@isif.app"),
            SIFRecipient(name: "Ada Lovelace", email: "ada@isif.app")
        ]
    }
}

// Back-compat alias if old code referenced FriendsService
public typealias FriendsService = FriendService
