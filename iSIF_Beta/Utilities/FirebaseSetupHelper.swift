import Foundation
import FirebaseFirestore

public class FirebaseSetupHelper {
    
    /// Creates a new user document with all required fields
    public static func createUserDocument(uid: String, email: String, displayName: String? = nil) async throws {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(uid)
        
        let userData: [String: Any] = [
            "displayName": displayName ?? "",
            "email": email,
            "phone": "",
            "gender": "",
            "location": "",
            "bio": "",
            "dateOfBirth": "",
            "photoURL": "",
            "friends": [],
            "blocked": [],
            "groups": [],
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        try await userRef.setData(userData)
    }
    
    /// Updates user profile data
    public static func updateUserProfile(uid: String, data: [String: Any]) async throws {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(uid)
        
        var updateData = data
        updateData["updatedAt"] = FieldValue.serverTimestamp()
        
        try await userRef.updateData(updateData)
    }
    
    /// Creates a friend request document
    public static func createFriendRequest(from: String, fromName: String, fromEmail: String,
                                         to: String, toName: String, toEmail: String) async throws {
        let db = Firestore.firestore()
        let requestId = "\(from)__\(to)"
        let requestRef = db.collection("friendRequests").document(requestId)
        
        let requestData: [String: Any] = [
            "from": from,
            "fromName": fromName,
            "fromEmail": fromEmail,
            "to": to,
            "toName": toName,
            "toEmail": toEmail,
            "status": "pending",
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        try await requestRef.setData(requestData)
    }
    
    /// Creates a SIF document with all current fields
    public static func createSIFDocument(_ sif: SIF) async throws -> String {
        let db = Firestore.firestore()
        let sifRef = db.collection("SIFs").document(sif.id)
        
        var sifData: [String: Any] = [
            "id": sif.id,
            "senderUID": sif.senderUID,
            "recipients": sif.recipients.map { ["id": $0.id, "name": $0.name, "email": $0.email] },
            "message": sif.message,
            "deliveryType": sif.deliveryType,
            "deliveryChannel": sif.deliveryChannel,
            "createdAt": sif.createdAt,
            "status": sif.status
        ]
        
        // Add optional fields if they exist
        if let subject = sif.subject {
            sifData["subject"] = subject
        }
        if let deliveryDate = sif.deliveryDate {
            sifData["deliveryDate"] = deliveryDate
        }
        if let signatureURLString = sif.signatureURLString {
            sifData["signatureURLString"] = signatureURLString
        }
        if let attachments = sif.attachments {
            sifData["attachments"] = attachments
        }
        if let templateName = sif.templateName {
            sifData["templateName"] = templateName
        }
        if let textOverlay = sif.textOverlay {
            sifData["textOverlay"] = textOverlay
        }
        
        try await sifRef.setData(sifData)
        return sif.id
    }
}
