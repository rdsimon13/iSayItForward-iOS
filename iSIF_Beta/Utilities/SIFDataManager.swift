import Foundation
import FirebaseFirestore

final class SIFDataManager {

    static let shared = SIFDataManager()
    private init() {}

    // ✅ Always use the same collection name
    private let collectionName = "SIFs"
    private var db: Firestore { Firestore.firestore() }

    // MARK: - Save or Update SIF
    func saveSIF(_ sif: SIF) async throws {
        let encoder = Firestore.Encoder()
        do {
            let data = try encoder.encode(sif)
            print("🧾 Writing to Firestore collection path: \(collectionName)")
            print("📄 Data to be written: \(data)")

            try await db.collection(collectionName)
                .document(sif.id)
                .setData(data, merge: true)

            print("✅ SIF successfully written to Firestore with ID: \(sif.id)")
        } catch {
            print("❌ Error writing SIF: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Fetch SIFs for a User
    func fetchUserSIFs(for userId: String) async throws -> [SIF] {
        print("📡 Fetching SIFs for user: \(userId) from \(collectionName)...")
        let decoder = Firestore.Decoder()
        do {
            let snapshot = try await db.collection(collectionName)
                .whereField("senderId", isEqualTo: userId)
                .order(by: "createdAt", descending: true)
                .limit(to: 100)
                .getDocuments()

            print("📦 Retrieved \(snapshot.documents.count) SIF(s) for user: \(userId)")

            let sifs = snapshot.documents.compactMap {
                try? $0.data(as: SIF.self)
            }

            return sifs
        } catch {
            print("❌ Error fetching SIFs: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Delete SIF (optional)
    func deleteSIF(_ sifId: String) async throws {
        try await db.collection(collectionName)
            .document(sifId)
            .delete()
        print("🗑️ SIF \(sifId) deleted successfully.")
    }
}
