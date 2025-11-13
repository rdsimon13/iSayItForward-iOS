//  SIFDataManager.swift
//  iSIF_Beta
//
//  Single source of truth for Firestore SIF operations.

import Foundation
import FirebaseFirestore

final class SIFDataManager {

    static let shared = SIFDataManager()
    private let col = Firestore.firestore().collection("SIFs")

    // MARK: - Send (create/merge)
    func sendSIF(_ sif: SIF, for uid: String) async throws {
        var data: [String: Any] = [
            "id": sif.id,
            "senderId": sif.senderUID,
            "message": sif.message,
            "deliveryType": sif.deliveryType.rawValue,
            "status": sif.status,
            "createdAt": Timestamp(date: sif.createdAt),
            "recipients": sif.recipients.map {
                ["id": $0.id, "name": $0.name, "email": $0.email]
            }
        ]
        if let subject = sif.subject { data["subject"] = subject }
        if let when = sif.scheduledAt { data["scheduledAt"] = Timestamp(date: when) }
        if let url = sif.signatureURL { data["signatureURL"] = url.absoluteString }

        print("🧾 Writing to Firestore collection path: \(col.path)")
        print("📄 Data to be written: \(data)")

        try await col.document(sif.id).setData(data, merge: true)

        print("✅ SIF successfully written to Firestore.")
    }

    // MARK: - Fetch user SIFs (sent)
    func fetchUserSIFs(for uid: String) async throws -> [SIF] {
        let snapshot = try await col
            .whereField("senderId", isEqualTo: uid)
            .order(by: "createdAt", descending: true)
            .limit(to: 100)
            .getDocuments()

        let sifs = snapshot.documents.compactMap { doc -> SIF? in
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: doc.data(), options: [])
                return try JSONDecoder().decode(SIF.self, from: jsonData)
            } catch {
                print("⚠️ Could not decode SIF \(doc.documentID): \(error)")
                return nil
            }
        }

        print("📦 Retrieved \(sifs.count) SIFs for user: \(uid)")
        return sifs
    }
}
