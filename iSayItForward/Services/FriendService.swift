import Foundation
import FirebaseFirestore
import FirebaseAuth

// MARK: - UserFriend Model
struct UserFriend: Identifiable, Hashable, Codable {
    var id: String
    var name: String
    var email: String
    var photoURL: String?
}

// MARK: - FriendRequest Model
struct FriendRequest: Identifiable, Codable {
    var id: String
    var fromUserId: String
    var fromName: String
    var fromEmail: String
    var toUserId: String
    var status: String // "pending", "accepted", "rejected"
}

// MARK: - FriendService
@MainActor
final class FriendService: ObservableObject {
    private let db = Firestore.firestore()

    // MARK: - Firestore Async Helpers

    /// Wraps Firestore's `getDocuments` in async/await
    private func getDocumentsAsync(_ query: Query) async throws -> QuerySnapshot {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<QuerySnapshot, Error>) in
            query.getDocuments { snapshot, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let snapshot = snapshot {
                    continuation.resume(returning: snapshot)
                } else {
                    continuation.resume(throwing: NSError(domain: "Firestore", code: -1))
                }
            }
        }
    }

    /// Wraps Firestore's `setData` in async/await
    private func setDataAsync(_ document: DocumentReference, data: [String: Any]) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            document.setData(data) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    // MARK: - Fetch All Users
    func fetchAllUsers(excluding userId: String) async throws -> [UserFriend] {
        print("📡 Fetching all users excluding \(userId)...")

        let query = db.collection("users")
        let snapshot = try await getDocumentsAsync(query)

        let users = snapshot.documents.compactMap { doc -> UserFriend? in
            guard doc.documentID != userId else { return nil }
            let data = doc.data()
            return UserFriend(
                id: doc.documentID,
                name: data["name"] as? String ?? "Unknown",
                email: data["email"] as? String ?? "",
                photoURL: data["photoURL"] as? String
            )
        }

        print("✅ Loaded \(users.count) users.")
        return users
    }

    // MARK: - Fetch Friends
    func fetchFriends(for userId: String) async throws -> [UserFriend] {
        print("👯 Fetching friends for user \(userId)...")

        let query = db.collection("users")
            .document(userId)
            .collection("friends")

        let snapshot = try await getDocumentsAsync(query)
        let friends = snapshot.documents.compactMap { doc -> UserFriend? in
            let data = doc.data()
            return UserFriend(
                id: doc.documentID,
                name: data["name"] as? String ?? "Unknown",
                email: data["email"] as? String ?? "",
                photoURL: data["photoURL"] as? String
            )
        }

        print("✅ Loaded \(friends.count) friends.")
        return friends
    }

    // MARK: - Fetch Sent Requests
    func fetchSentRequests(for userId: String) async throws -> Set<String> {
        print("📨 Fetching sent friend requests for user \(userId)...")

        let query = db.collection("friendRequests")
            .whereField("fromUserId", isEqualTo: userId)

        let snapshot = try await getDocumentsAsync(query)
        let sentRequests = Set(snapshot.documents.compactMap { $0.data()["toUserId"] as? String })

        print("✅ Found \(sentRequests.count) sent requests.")
        return sentRequests
    }

    // MARK: - Send Friend Request
    func sendFriendRequest(
        from fromId: String,
        fromName: String,
        fromEmail: String,
        to toId: String
    ) async throws {
        print("📬 Sending friend request from \(fromName) → \(toId)...")

        let ref = db.collection("friendRequests").document()

        let data: [String: Any] = [
            "id": ref.documentID,
            "fromUserId": fromId,
            "fromName": fromName,
            "fromEmail": fromEmail,
            "toUserId": toId,
            "status": "pending",
            "createdAt": FieldValue.serverTimestamp()
        ]

        try await setDataAsync(ref, data: data)
        print("✅ Friend request sent successfully!")
    }

    // MARK: - Accept Friend Request
    func acceptFriendRequest(_ request: FriendRequest) async throws {
        print("🤝 Accepting friend request from \(request.fromUserId) to \(request.toUserId)...")

        // Update status
        let requestRef = db.collection("friendRequests").document(request.id)
        try await setDataAsync(requestRef, data: ["status": "accepted"])

        // Add each other as friends
        let senderRef = db.collection("users").document(request.fromUserId)
            .collection("friends").document(request.toUserId)
        let recipientRef = db.collection("users").document(request.toUserId)
            .collection("friends").document(request.fromUserId)

        let senderFriendData: [String: Any] = [
            "id": request.toUserId,
            "name": request.fromName,
            "email": request.fromEmail
        ]

        let recipientFriendData: [String: Any] = [
            "id": request.fromUserId,
            "name": request.fromName,
            "email": request.fromEmail
        ]

        try await setDataAsync(senderRef, data: recipientFriendData)
        try await setDataAsync(recipientRef, data: senderFriendData)

        print("✅ Friendship established between \(request.fromUserId) and \(request.toUserId).")
    }

    // MARK: - Reject Friend Request
    func rejectFriendRequest(_ requestId: String) async throws {
        print("❌ Rejecting friend request \(requestId)...")

        let ref = db.collection("friendRequests").document(requestId)
        try await setDataAsync(ref, data: ["status": "rejected"])

        print("✅ Friend request rejected.")
    }
}
