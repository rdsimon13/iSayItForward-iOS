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
            print("🧾 Writing to Firestore collection: \(collectionName)")
            print("🧾 Firestore project: \(FirebaseApp.app()?.options.projectID ?? "unknown")")
            print("📄 Document ID: \(sif.id)")
            print("📄 Data to be written: \(data)")

            try await db.collection(collectionName)
                .document(sif.id)
                .setData(data, merge: true)

            print("✅ SIF successfully written to Firestore with ID: \(sif.id)")
            
            // Verify the document was written
            let doc = try await db.collection(collectionName).document(sif.id).getDocument()
            if doc.exists {
                print("✅ Document verified to exist after write")
            } else {
                print("❌ Document does not exist after write!")
            }
        } catch {
            print("❌ Error writing SIF: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Fetch SIFs for a User
    func fetchUserSIFs(for userId: String) async throws -> [SIF] {
        print("📡 Fetching SIFs for user: \(userId) from \(collectionName)...")
        do {
            let snapshot = try await db.collection(collectionName)
                .whereField("senderUID", isEqualTo: userId)
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
