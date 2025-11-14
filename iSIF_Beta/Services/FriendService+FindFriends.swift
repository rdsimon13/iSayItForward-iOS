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
    
    func fetchReceivedRequests(for uid: String) async throws -> [UserFriend] {
        let db = Firestore.firestore()
        let q = db.collection("friendRequests")
            .whereField("to", isEqualTo: uid)
            .whereField("status", isEqualTo: "pending")
        let snap = try await q.getDocumentsAsync()
        return snap.documents.compactMap { doc in
            let data = doc.data()
            guard let from = data["from"] as? String,
                  let fromName = data["fromName"] as? String,
                  let fromEmail = data["fromEmail"] as? String else { return nil }
            return UserFriend(id: from, name: fromName, email: fromEmail)
        }
    }
    
    func fetchFriends(for uid: String) async throws -> [UserFriend] {
        let db = Firestore.firestore()
        let userDoc = try await db.collection("users").document(uid).getDocument()
        guard let data = userDoc.data(),
              let friendIds = data["friends"] as? [String] else {
            return []
        }
        
        if friendIds.isEmpty { return [] }
        
        let q = db.collection("users").whereField(FieldPath.documentID(), in: friendIds)
        let snap = try await q.getDocumentsAsync()
        return snap.documents.compactMap { doc in
            let data = doc.data()
            let name = (data["name"] as? String) 
                   ?? (data["displayName"] as? String)
                   ?? (data["fullName"] as? String)
            let email = data["email"] as? String ?? ""
            guard let name = name else { return nil }
            return UserFriend(id: doc.documentID, name: name, email: email)
        }
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
    
    func acceptFriendRequest(from: String, to: String) async throws {
        let db = Firestore.firestore()
        let docID = "\(from)__\(to)"
        let requestRef = db.collection("friendRequests").document(docID)
        
        // Update request status
        try await requestRef.updateData(["status": "accepted"])
        
        // Add to both users' friends lists
        let currentUserRef = db.collection("users").document(to)
        let senderUserRef = db.collection("users").document(from)
        
        try await currentUserRef.updateData([
            "friends": FieldValue.arrayUnion([from])
        ])
        try await senderUserRef.updateData([
            "friends": FieldValue.arrayUnion([to])
        ])
    }
    
    func declineFriendRequest(from: String, to: String) async throws {
        let db = Firestore.firestore()
        let docID = "\(from)__\(to)"
        let requestRef = db.collection("friendRequests").document(docID)
        try await requestRef.delete()
    }
}
