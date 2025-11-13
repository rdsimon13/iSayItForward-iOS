import Foundation
import FirebaseFirestore

// Minimal shim so ComposeSIFView can call `sendSIF(_:for:)` on SIFDataManager.
extension SIFDataManager {
    /// Writes a SIF under /users/{uid}/sifs/{sif.id}. Adjust path later if needed.
    func sendSIF(_ sif: SIF, for uid: String) async throws {
        let db = Firestore.firestore()
        let ref = db.collection("users").document(uid).collection("sifs").document(sif.id)

        // Map recipients -> dictionaries for Firestore
        let recipientsPayload: [[String: Any]] = sif.recipients.map {
            ["id": $0.id, "name": $0.name, "email": $0.email]
        }

        var payload: [String: Any] = [
            "id": sif.id,
            "senderUID": sif.senderUID,
            "recipients": recipientsPayload,
            "message": sif.message,
            "deliveryType": sif.deliveryType.rawValue,
            "createdAt": FieldValue.serverTimestamp()
        ]

        // Optional fields (avoid nil-crash by storing NSNull when absent)
        if let subject = sif.subject { payload["subject"] = subject } else { payload["subject"] = NSNull() }
        if let when = sif.scheduledAt { payload["scheduledAt"] = Timestamp(date: when) } else { payload["scheduledAt"] = NSNull() }

        try await ref.setData(payload, merge: true)
    }
}
