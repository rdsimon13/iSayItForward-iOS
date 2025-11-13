// FriendService+FindFriends.swift
import Foundation
import FirebaseFirestore
import FirebaseCore

// NOTE: Do NOT redeclare `FriendService` here.
// NOTE: Assume `public typealias UserFriend = SIFRecipient` already exists (LegacyCompat.swift).

public extension FriendService {

    /// Returns all users except the caller.
    func fetchAllUsers(excluding uid: String) async throws -> [UserFriend] {
        return try await withCheckedThrowingContinuation { continuation in
            let db = Firestore.firestore()
            db.collection("users")
                .whereField(FieldPath.documentID(), isNotEqualTo: uid)
                .getDocuments { snapshot, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    guard let snapshot = snapshot else {
                        continuation.resume(throwing: NSError(domain: "FriendService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Snapshot is nil"]))
                        return
                    }
                    let users: [UserFriend] = snapshot.documents.compactMap { doc in
                        let data = doc.data()
                        let name = data["name"] as? String ?? data["displayName"] as? String ?? data["fullName"] as? String ?? data["email"] as? String ?? "Unknown"
                        let email = data["email"] as? String ?? ""
                        return UserFriend(id: doc.documentID, name: name, email: email)
                    }
                    continuation.resume(returning: users)
                }
        }
    }

    /// IDs the current user has already requested.
    func fetchSentRequests(for uid: String) async throws -> Set<String> {
        return try await withCheckedThrowingContinuation { continuation in
            let db = Firestore.firestore()
            db.collection("friendRequests")
                .whereField("from", isEqualTo: uid)
                .getDocuments { snapshot, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    guard let snapshot = snapshot else {
                        continuation.resume(throwing: NSError(domain: "FriendService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Snapshot is nil"]))
                        return
                    }
                    let sentTo = Set(snapshot.documents.compactMap { $0.data()["to"] as? String })
                    continuation.resume(returning: sentTo)
                }
        }
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
        return try await withCheckedThrowingContinuation { continuation in
            let db = Firestore.firestore()
            let docID = "\(from)__\(to)" // deterministic, prevents dupes
            let ref = db.collection("friendRequests").document(docID)
            ref.setData([
                "from": from,
                "fromName": fromName,
                "fromEmail": fromEmail,
                "to": to,
                "toName": toName,
                "toEmail": toEmail,
                "status": "pending",
                "createdAt": FieldValue.serverTimestamp()
            ]) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}
