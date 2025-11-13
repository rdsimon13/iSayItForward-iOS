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
        do {
            let encoder = Firestore.Encoder()
            let data = try encoder.encode(sif)
            
            print("🧾 Writing to Firestore collection path: \(col.path)")
            print("📄 Data to be written: \(data)")

            try await col.document(sif.id).setData(data, merge: true)

            print("✅ SIF successfully written to Firestore with ID: \(sif.id)")
        } catch {
            print("❌ Firestore encoding/write failed: \(error)")
            throw error
        }
    }

    // MARK: - Fetch user SIFs (sent)
    func fetchUserSIFs(for uid: String) async throws -> [SIF] {
        let snapshot = try await col
            .whereField("senderId", isEqualTo: uid)
            .order(by: "createdAt", descending: true)
            .limit(to: 100)
            .getDocuments()

        let decoder = Firestore.Decoder()
        let sifs = snapshot.documents.compactMap { doc -> SIF? in
            do {
                return try decoder.decode(SIF.self, from: doc.data())
            } catch {
                print("⚠️ Could not decode SIF \(doc.documentID): \(error)")
                return nil
            }
        }

        print("📦 Retrieved \(sifs.count) SIFs for user: \(uid)")
        return sifs
    }
}
