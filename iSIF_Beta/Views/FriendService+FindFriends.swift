// FriendService+FindFriends.swift
import Foundation
import FirebaseFirestore

// NOTE: Do NOT redeclare `FriendService` here.
// NOTE: Assume `public typealias UserFriend = SIFRecipient` already exists (LegacyCompat.swift).

public extension FriendService {

    /// Returns all users except the caller.
    func fetchAllUsers(excluding uid: String) async throws -> [UserFriend] {
        let db = Firestore.firestore()
        let snap = try await db.collection("users").getDocuments()

        let users: [UserFriend] = snap.documents.compactMap { doc in
            guard doc.documentID != uid else { return nil }

            let name =
                (doc.get("name") as? String) ??
                (doc.get("displayName") as? String) ??
                (doc.get("fullName") as? String) ??
                (doc.get("email") as? String) ??
                "Unknown"

            let email = (doc.get("email") as? String) ?? ""

            return UserFriend(id: doc.documentID, name: name, email: email)
        }
        return users
    }

    /// IDs the current user has already requested.
    func fetchSentRequests(for uid: String) async throws -> Set<String> {
        let db = Firestore.firestore()
        let q = db.collection("friendRequests").whereField("from", isEqualTo: uid)
        let snap = try await q.getDocuments()
        return Set(snap.documents.compactMap { $0.get("to") as? String })
    }

    /// Creates/merges a pending friend request (idempotent).
    func sendFriendRequest(
        from: String,
        fromName: String,
        fromEmail: String,
        to: String,
        toName: String,
        toEmail: String
    ) async throws {
        let db = Firestore.firestore()
        let docID = "\(from)__\(to)" // deterministic, prevents dupes
        let ref = db.collection("friendRequests").document(docID)
        try await ref.setData([
            "from": from,
            "fromName": fromName,
            "fromEmail": fromEmail,
            "to": to,
            "toName": toName,
            "toEmail": toEmail,
            "status": "pending",
            "createdAt": FieldValue.serverTimestamp()
        ], merge: true)
    }
}
