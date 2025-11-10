/*
import Foundation
import FirebaseFirestore
import FirebaseStorage

struct SIFRecipient: Codable, Identifiable { ... }

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
}//
//  SIF.swift
//  iSIF_Beta
//
//  Created by Reginald Simon on 11/5/25.
//
/*
import Foundation
import FirebaseFirestore
import FirebaseStorage

// MARK: - Recipient Model
struct SIFRecipient: Codable, Identifiable {
    var id: String
    var name: String
    var email: String

    // ✅ Default UUID init (so no manual id needed)
    init(id: String = UUID().uuidString, name: String, email: String) {
        self.id = id
        self.name = name
        self.email = email
    }
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

    // MARK: - Async Firestore Writes
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

    // MARK: - Async Firestore Reads
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

        let docRef = db.collection("users")
            .document(userId)
            .collection("sifs")
            .document(id)

        try await setDataAsync(docRef, from: newSIF)
        print("✅ Firestore write complete for SIF ID: \(id)")
    }

    // MARK: - Send (Global)
    func sendSIF(_ sif: SIF) async throws {
        print("🌍 Sending SIF globally")

        var newSIF = sif
        if newSIF.id == nil { newSIF.id = UUID().uuidString }
        guard let id = newSIF.id else { throw NSError(domain: "SIFService", code: 0) }

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

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            db.collection("SIFs").document(id).setData(data) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }

        print("✅ Global Firestore SIF saved successfully.")
    }

    // MARK: - Schedule
    func scheduleSIF(_ sif: SIF, for userId: String) async throws {
        print("🕒 Scheduling SIF for user \(userId)")
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
        guard let id = sif.id else { throw NSError(domain: "SIFService", code: 1) }

        let docRef = db.collection("users")
            .document(userId)
            .collection("sifs")
            .document(id)

        try await setDataAsync(docRef, from: sif)
        print("✅ Updated SIF: \(id)")
    }

    // MARK: - Delete
    func deleteSIF(_ id: String, for userId: String) async throws {
        print("🗑️ Deleting SIF \(id) for user \(userId)")

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

    // MARK: - Fetch
    func fetchUserSIFs(for userId: String) async throws -> [SIF] {
        print("📬 Fetching SIFs for user \(userId)...")
        let query = db.collection("users")
            .document(userId)
            .collection("sifs")
            .order(by: "createdAt", descending: true)

        let snapshot = try await getDocumentsAsync(query)
        return snapshot.documents.compactMap { try? $0.data(as: SIF.self) }
    }

    // MARK: - Real-time Listen
    func observeUserSIFs(for userId: String, onChange: @escaping ([SIF]) -> Void) -> ListenerRegistration {
        db.collection("users")
            .document(userId)
            .collection("sifs")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, error in
                guard let snapshot else {
                    print("❌ Error: \(error?.localizedDescription ?? "Unknown")")
                    return
                }
                let sifs = snapshot.documents.compactMap { try? $0.data(as: SIF.self) }
                onChange(sifs)
            }
    }

    // MARK: - Upload
    func uploadAttachment(_ data: Data, fileName: String) async throws -> String {
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

 */*/
