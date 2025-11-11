import Foundation
import FirebaseAuth
import FirebaseFirestore

public protocol SIFProviding {
    @discardableResult
    func saveSIF(_ sif: SIF) async throws -> String
    func fetchSentSIFs(for uid: String) async throws -> [SIF]
}

public class SIFService: SIFProviding {
    private let db = Firestore.firestore()
    
    public init() {}
    
    @discardableResult
    public func saveSIF(_ sif: SIF) async throws -> String {
        let docRef = db.collection("users").document(sif.senderUID).collection("sifs").document(sif.id)
        try await docRef.setData([
            "id": sif.id,
            "senderUID": sif.senderUID,
            "recipients": sif.recipients.map { ["id": $0.id, "name": $0.name, "email": $0.email] },
            "subject": sif.subject as Any,
            "message": sif.message,
            "deliveryType": sif.deliveryType.rawValue,
            "scheduledAt": sif.scheduledAt as Any,
            "createdAt": sif.createdAt,
            "status": sif.status
        ])
        return docRef.documentID
    }
    
    public func fetchSentSIFs(for uid: String) async throws -> [SIF] {
        let snapshot = try await db.collection("users").document(uid).collection("sifs").getDocuments()
        return snapshot.documents.compactMap { doc in
            let data = doc.data()
            guard let senderUID = data["senderUID"] as? String,
                  let recipientsData = data["recipients"] as? [[String: Any]],
                  let message = data["message"] as? String,
                  let deliveryTypeRaw = data["deliveryType"] as? String,
                  let deliveryType = DeliveryType(rawValue: deliveryTypeRaw),
                  let createdAt = data["createdAt"] as? Date,
                  let status = data["status"] as? String else {
                return nil
            }
            
            let recipients = recipientsData.compactMap { recipientData -> SIFRecipient? in
                guard let id = recipientData["id"] as? String,
                      let name = recipientData["name"] as? String,
                      let email = recipientData["email"] as? String else {
                    return nil
                }
                return SIFRecipient(id: id, name: name, email: email)
            }
            
            return SIF(
                id: doc.documentID,
                senderUID: senderUID,
                recipients: recipients,
                subject: data["subject"] as? String,
                message: message,
                deliveryType: deliveryType,
                scheduledAt: data["scheduledAt"] as? Date,
                createdAt: createdAt,
                status: status
            )
        }
    }
}
