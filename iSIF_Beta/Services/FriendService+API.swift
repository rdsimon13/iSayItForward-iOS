import Foundation
import FirebaseFirestore

// FriendService class already exists elsewhere. Do NOT redeclare it.
public extension FriendService {
    func fetchAllUsers(excluding uid: String) async throws -> [UserFriend] {
        let db = Firestore.firestore()
        let snap = try await db.collection("users").getDocuments()
        return snap.documents.compactMap { doc in
            guard doc.documentID != uid else { return nil }
            let name = (doc.get("name") as? String)
                ?? (doc.get("displayName") as? String)
                ?? (doc.get("fullName") as? String)
                ?? (doc.get("email") as? String)
                ?? "Unknown"
            let email = (doc.get("email") as? String) ?? ""
            return UserFriend(id: doc.documentID, name: name, email: email)
        }
    }

    func fetchSentRequests(for uid: String) async throws -> Set<String> {
        let db = Firestore.firestore()
        let q = db.collection("friendRequests").whereField("from", isEqualTo: uid)
        let snap = try await q.getDocuments()
        return Set(snap.documents.compactMap { $0.get("to") as? String })
    }

    func sendFriendRequest(
        from: String,
        fromName: String,
        fromEmail: String,
        to: String,
        toName: String,
        toEmail: String
    ) async throws {
        let db = Firestore.firestore()
        let docID = "\(from)__\(to)"   // deterministic; avoids dupes
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
