import Foundation
import FirebaseFirestore

extension SIFDataManager {

    /// Async load of the current user's SIFs.
    func fetchUserSIFs(for uid: String) async throws -> [SIF] {
        let db = Firestore.firestore()
        let snap = try await db.collection("sifs")
            .whereField("senderUID", isEqualTo: uid)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return snap.documents.compactMap { doc in
            let data = doc.data()

            // recipients
            let recipientDicts = (data["recipients"] as? [[String: Any]]) ?? []
            let recipients: [SIFRecipient] = recipientDicts.compactMap {
                guard let name = $0["name"] as? String,
                      let email = $0["email"] as? String else { return nil }
                return SIFRecipient(
                    id: $0["id"] as? String ?? UUID().uuidString,
                    name: name,
                    email: email
                )
            }

            // deliveryType
            let raw = (data["deliveryType"] as? String) ?? "oneToOne"
            let delivery = DeliveryType(rawValue: raw) ?? .oneToOne

            let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
            let scheduledAt = (data["scheduledAt"] as? Timestamp)?.dateValue()

            return SIF(
                id: doc.documentID,
                senderUID: data["senderUID"] as? String ?? uid,
                recipients: recipients,
                subject: data["subject"] as? String,
                message: data["message"] as? String ?? "",
                deliveryType: delivery,
                scheduledAt: scheduledAt,
                createdAt: createdAt,
                status: (data["status"] as? String) ?? "sent"
            )
        }
    }

    /// Realtime listener for the user's SIFs. Caller owns the returned registration.
    @discardableResult
    func observeUserSIFs(for uid: String, onChange: @escaping ([SIF]) -> Void) -> ListenerRegistration {
        let db = FirebaseFirestore.Firestore.firestore()
        return db.collection("sifs")
            .whereField("senderUID", isEqualTo: uid)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                let mapped: [SIF] = docs.compactMap { doc in
                    let data = doc.data()

                    let recipientDicts = (data["recipients"] as? [[String: Any]]) ?? []
                    let recipients: [SIFRecipient] = recipientDicts.compactMap {
                        guard let name = $0["name"] as? String,
                              let email = $0["email"] as? String else { return nil }
                        return SIFRecipient(
                            id: $0["id"] as? String ?? UUID().uuidString,
                            name: name,
                            email: email
                        )
                    }

                    let raw = (data["deliveryType"] as? String) ?? "oneToOne"
                    let delivery = DeliveryType(rawValue: raw) ?? .oneToOne

                    let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    let scheduledAt = (data["scheduledAt"] as? Timestamp)?.dateValue()

                    return SIF(
                        id: doc.documentID,
                        senderUID: data["senderUID"] as? String ?? uid,
                        recipients: recipients,
                        subject: data["subject"] as? String,
                        message: data["message"] as? String ?? "",
                        deliveryType: delivery,
                        scheduledAt: scheduledAt,
                        createdAt: createdAt,
                        status: (data["status"] as? String) ?? "sent"
                    )
                }
                onChange(mapped)
            }
    }
}
