// Services/FriendService+FindFriends.swift
import Foundation
import FirebaseAuth
import FirebaseFirestore

public extension FriendService {
    typealias UserFriend = SIFRecipient

    func fetchAllUsers(excluding uid: String) async throws -> [UserFriend] {
        let db = Firestore.firestore()
        let q = db.collection("users")
            .whereField(FieldPath.documentID(), isNotEqualTo: uid)

        let snap = try await q.getDocumentsAsync()
        return snap.documents.compactMap { doc in
            let d = doc.data()
            let name = (d["name"] as? String)
                   ?? (d["displayName"] as? String)
                   ?? (d["fullName"] as? String)
            let email = (d["email"] as? String) ?? ""
            guard let name else { return nil }
            return UserFriend(id: doc.documentID, name: name, email: email)
        }
    }

    func fetchSentRequests(for uid: String) async throws -> Set<String> {
        let db = Firestore.firestore()
        let q  = db.collection("friendRequests").whereField("from", isEqualTo: uid)
        let snap = try await q.getDocumentsAsync()
        return Set(snap.documents.compactMap { $0.data()["to"] as? String })
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
