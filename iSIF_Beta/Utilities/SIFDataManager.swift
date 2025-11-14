import Foundation
import FirebaseCore
import FirebaseFirestore

final class SIFDataManager {
    static let shared = SIFDataManager()
    private init() {}

    private let collectionName = "SIFs"
    private var db: Firestore { Firestore.firestore() }

    // MARK: - Save or Update SIF
    func saveSIF(_ sif: SIF) async throws {
        var sifToSave = sif

        // Use existing ID if available; otherwise, generate a new one
        let documentRef: DocumentReference
        if !sifToSave.id.isEmpty {
            documentRef = db.collection(collectionName).document(sifToSave.id)
        } else {
            documentRef = db.collection(collectionName).document()
            sifToSave.id = documentRef.documentID
        }

        // Convert SIF to dictionary for Firestore
        var sifData: [String: Any] = [
            "id": sifToSave.id,
            "senderUID": sifToSave.senderUID,
            "recipients": sifToSave.recipients.map { ["id": $0.id, "name": $0.name, "email": $0.email] },
            "message": sifToSave.message,
            "deliveryType": sifToSave.deliveryType,
            "deliveryChannel": sifToSave.deliveryChannel,
            "createdAt": sifToSave.createdAt,
            "status": sifToSave.status
        ]
        
        // Add optional fields
        if let subject = sifToSave.subject {
            sifData["subject"] = subject
        }
        if let deliveryDate = sifToSave.deliveryDate {
            sifData["deliveryDate"] = deliveryDate
        }
        if let signatureURLString = sifToSave.signatureURLString {
            sifData["signatureURLString"] = signatureURLString
        }
        if let attachments = sifToSave.attachments {
            sifData["attachments"] = attachments
        }
        if let templateName = sifToSave.templateName {
            sifData["templateName"] = templateName
        }
        if let textOverlay = sifToSave.textOverlay {
            sifData["textOverlay"] = textOverlay
        }

        // Debug output
        print("🧾 Writing to Firestore collection: \(collectionName)")
        print("🧾 Document ID: \(sifToSave.id)")
        print("📄 SIF data: \(sifData)")

        // Write data to Firestore
        try await documentRef.setData(sifData)
        print("✅ SIF successfully written to Firestore with ID: \(sifToSave.id)")

        // Verify the document was written correctly
        let snapshot = try await documentRef.getDocument()
        if snapshot.exists {
            print("✅ Document verified to exist after write")
        } else {
            print("❌ Document not found after write")
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

            let sifs: [SIF] = snapshot.documents.compactMap { document in
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

    // MARK: - Fetch Received SIFs for a User (for inbox)
    func fetchReceivedSIFs(for userId: String) async throws -> [SIF] {
        print("📡 Fetching received SIFs for user: \(userId)...")

        do {
            let snapshot = try await db.collection(collectionName)
                .whereField("recipients", arrayContains: userId)
                .order(by: "createdAt", descending: true)
                .limit(to: 100)
                .getDocuments()

            print("📦 Retrieved \(snapshot.documents.count) received SIF document(s)")

            let sifs: [SIF] = snapshot.documents.compactMap { document in
                do {
                    return try document.data(as: SIF.self)
                } catch {
                    print("❌ Error decoding document \(document.documentID): \(error)")
                    return nil
                }
            }

            print("✅ Successfully decoded \(sifs.count) received SIF(s)")
            return sifs
        } catch {
            print("❌ Error fetching received SIFs: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Delete SIF
    func deleteSIF(withId sifId: String) async throws {
        print("🗑️ Attempting to delete SIF with ID: \(sifId)")
        try await db.collection(collectionName).document(sifId).delete()
        print("✅ SIF \(sifId) deleted successfully.")
    }
}
