// FriendService+FindFriends.swift
import Foundation
import FirebaseFirestore

public extension FriendService {
    typealias UserFriend = SIFRecipient

    func fetchAllUsers(excluding uid: String) async throws -> [UserFriend] {
        let db = Firestore.firestore()
        let query = db.collection("users")
            .whereField(FieldPath.documentID(), isNotEqualTo: uid)

        let snap = try await query.getDocumentsAsync()

        let users: [UserFriend] = snap.documents.compactMap { doc in
            let data = doc.data()
            let name = (data["name"] as? String) 
                     ?? (data["displayName"] as? String)
                     ?? (data["fullName"] as? String)
                     ?? "Unknown"
            let email = (data["email"] as? String) ?? ""
            return UserFriend(id: doc.documentID, name: name, email: email)
        }
        return users
    }

    func fetchSentRequests(for uid: String) async throws -> Set<String> {
        let db = Firestore.firestore()
        let q = db.collection("friendRequests")
            .whereField("from", isEqualTo: uid)

        let snap = try await q.getDocumentsAsync()
        let ids: [String] = snap.documents.compactMap { $0.data()["to"] as? String }
        return Set(ids)
    }

    func sendFriendRequest(
        from: String, fromName: String, fromEmail: String,
        to: String,   toName: String,   toEmail: String
    ) async throws {
        let db = Firestore.firestore()
        let docID = "\(from)__\(to)"
        let ref = db.collection("friendRequests").document(docID)
        try await ref.setDataAsync([
            "from": from, "fromName": fromName, "fromEmail": fromEmail,
            "to": to,     "toName": toName,     "toEmail": toEmail,
            "status": "pending",
            "createdAt": FieldValue.serverTimestamp()
        ], merge: true)
    }
}
