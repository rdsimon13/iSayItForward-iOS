import Foundation
import FirebaseFirestore
import FirebaseStorage

// MARK: - Recipient Model
struct SIFRecipient: Codable, Identifiable {
    var id: String = UUID().uuidString
    var name: String
    var email: String
}

// MARK: - SIF Model
struct SIF: Codable, Identifiable {
    @DocumentID var id: String? = UUID().uuidString
    var senderId: String
    var recipients: [SIFRecipient]
    var subject: String
    var message: String
    var category: String
    var tone: String?
    var emotion: String?
    var templateId: String?
    var documentURL: String?
    var deliveryType: String
    var isScheduled: Bool
    var scheduledDate: Date?
    var createdAt: Date
    var status: String
}

// MARK: - SIF Service
@MainActor
final class SIFService: ObservableObject {
    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    // MARK: - Helper for async Firestore writes
    private func setDataAsync<T: Encodable>(
        _ document: DocumentReference,
        from value: T,
        merge: Bool = true
    ) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            do {
                try document.setData(from: value, merge: merge) { error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    // MARK: - Helper for async Firestore reads
    private func getDocumentsAsync(_ query: Query) async throws -> QuerySnapshot {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<QuerySnapshot, Error>) in
            query.getDocuments { snapshot, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let snapshot = snapshot {
                    continuation.resume(returning: snapshot)
                } else {
                    continuation.resume(throwing: NSError(domain: "Firestore", code: -1))
                }
            }
        }
    }

    // MARK: - Send (User Scoped)
    func sendSIF(_ sif: SIF, for userId: String) async throws {
        print("🔥 Firestore SEND triggered for user: \(userId)")

        var newSIF = sif
        if newSIF.id == nil { newSIF.id = UUID().uuidString }

        guard let id = newSIF.id else {
            throw NSError(domain: "SIFService", code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid SIF ID"])
        }

        print("📝 Writing SIF to Firestore path: users/\(userId)/sifs/\(id)")

        let docRef = db.collection("users")
            .document(userId)
            .collection("sifs")
            .document(id)

        try await setDataAsync(docRef, from: newSIF)
        print("✅ Firestore write complete for SIF ID: \(id)")
    }

    // MARK: - Send (Global Collection)
    func sendSIF(_ sif: SIF) async throws {
        print("🌍 Firestore SEND to global collection triggered")

        var newSIF = sif
        if newSIF.id == nil { newSIF.id = UUID().uuidString }

        guard let id = newSIF.id else {
            throw NSError(domain: "SIFService", code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid SIF ID"])
        }

        let data: [String: Any] = [
            "id": id,
            "senderId": newSIF.senderId,
            "recipients": newSIF.recipients.map {
                ["id": $0.id, "name": $0.name, "email": $0.email]
            },
            "subject": newSIF.subject,
            "message": newSIF.message,
            "category": newSIF.category,
            "tone": newSIF.tone ?? "",
            "emotion": newSIF.emotion ?? "",
            "templateId": newSIF.templateId ?? "",
            "documentURL": newSIF.documentURL ?? "",
            "deliveryType": newSIF.deliveryType,
            "isScheduled": newSIF.isScheduled,
            "scheduledDate": newSIF.scheduledDate?.timeIntervalSince1970 ?? 0,
            "createdAt": newSIF.createdAt.timeIntervalSince1970,
            "status": newSIF.status
        ]

        let docRef = db.collection("SIFs").document(id)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            docRef.setData(data) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }

        print("✅ Firestore global write complete for SIF ID: \(id)")
    }

    // MARK: - Schedule a SIF
    func scheduleSIF(_ sif: SIF, for userId: String) async throws {
        print("🕒 Scheduling SIF for user: \(userId)")

        var scheduledSIF = sif
        scheduledSIF.isScheduled = true
        scheduledSIF.status = "scheduled"

        guard let id = scheduledSIF.id else {
            throw NSError(domain: "SIFService", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "Missing SIF ID for scheduling"])
        }

        let docRef = db.collection("users")
            .document(userId)
            .collection("sifs")
            .document(id)

        try await setDataAsync(docRef, from: scheduledSIF)
        print("✅ Scheduled SIF saved successfully (ID: \(id))")
    }

    // MARK: - Update
    func updateSIF(_ sif: SIF, for userId: String) async throws {
        print("🔄 Updating SIF for user \(userId)")

        guard let id = sif.id else {
            throw NSError(domain: "SIFService", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Missing SIF ID for update"])
        }

        let docRef = db.collection("users")
            .document(userId)
            .collection("sifs")
            .document(id)

        try await setDataAsync(docRef, from: sif)
        print("✅ SIF update complete (ID: \(id))")
    }

    // MARK: - Delete
    func deleteSIF(_ id: String, for userId: String) async throws {
        print("🗑️ Deleting SIF \(id) for user \(userId)...")

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            db.collection("users")
                .document(userId)
                .collection("sifs")
                .document(id)
                .delete { error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
        }

        print("✅ SIF deleted successfully.")
    }

    // MARK: - Fetch All
    func fetchUserSIFs(for userId: String) async throws -> [SIF] {
        print("📬 Fetching SIFs for user \(userId)...")

        let query = db.collection("users")
            .document(userId)
            .collection("sifs")
            .order(by: "createdAt", descending: true)

        let snapshot = try await getDocumentsAsync(query)
        let sifs = snapshot.documents.compactMap { try? $0.data(as: SIF.self) }

        print("✅ Loaded \(sifs.count) SIFs for user \(userId)")
        return sifs
    }

    // MARK: - Real-time Listener
    func observeUserSIFs(for userId: String, onChange: @escaping ([SIF]) -> Void) -> ListenerRegistration {
        print("📡 Listening for SIF changes for user \(userId)...")

        return db.collection("users")
            .document(userId)
            .collection("sifs")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, error in
                guard let snapshot = snapshot else {
                    print("❌ Error observing SIFs: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }

                let sifs = snapshot.documents.compactMap { try? $0.data(as: SIF.self) }
                print("🔄 Real-time update: \(sifs.count) SIFs found.")
                onChange(sifs)
            }
    }

    // MARK: - Upload Attachment
    func uploadAttachment(_ data: Data, fileName: String) async throws -> String {
        print("📤 Uploading attachment \(fileName)...")

        let ref = storage.reference().child("sif_attachments/\(fileName)")

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            ref.putData(data, metadata: nil) { _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    ref.downloadURL { url, error in
                        if let url = url {
                            continuation.resume(returning: url.absoluteString)
                        } else {
                            continuation.resume(throwing: error ?? NSError(domain: "SIFService", code: -1))
                        }
                    }
                }
            }
        }
    }
}
