import Foundation
import FirebaseAuth

public protocol FriendsProviding {
    func fetchFriends() async throws -> [SIFRecipient]
}

public final class FriendService: FriendsProviding {
    public init() {}
    
    public func fetchFriends() async throws -> [SIFRecipient] {
        guard let currentUser = Auth.auth().currentUser else {
            return []
        }
        return try await fetchFriends(for: currentUser.uid)
    }
}

// Back-compat alias for code that referenced FriendsService
public typealias FriendsService = FriendService
