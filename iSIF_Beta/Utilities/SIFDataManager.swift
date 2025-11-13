import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

final class SIFDataManager {

    static let shared = SIFDataManager()
    private init() {}

    private let collectionName = "SIFs"
    private var db: Firestore { Firestore.firestore() }

    // MARK: - Save or Update SIF
    func saveSIF(_ sif: SIF) async throws {
        do {
            let documentRef = db.collection(collectionName).document()
            var sifToSave = sif
            sifToSave.id = documentRef.documentID
            
            print("🧾 Writing to Firestore collection: \(collectionName)")
            print("🧾 Firestore project: \(FirebaseApp.app()?.options.projectID ?? "unknown")")
            print("📄 Document ID: \(documentRef.documentID)")
            print("📄 SIF data: \(sifToSave)")

            try documentRef.setData(from: sifToSave, merge: false)

            print("✅ SIF successfully written to Firestore with ID: \(documentRef.documentID)")
            
            // Verify the document was written
            let doc = try await documentRef.getDocument()
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

            print("📦 Retrieved \(snapshot.documents.count) document(s) for user: \(userId)")

            let sifs = snapshot.documents.compactMap { document -> SIF? in
                do {
                    return try document.data(as: SIF.self)
                } catch {
                    print("❌ Error decoding document \(document.documentID): \(error)")
                    return nil
                }
            }

            print("✅ Successfully decoded \(sifs.count) SIF(s)")
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
