//
//  FirestoreAsyncCompat.swift
//  iSIF_Beta
//
//  Async/await wrappers so we don’t need FirebaseFirestoreSwift.
//

import Foundation
import FirebaseFirestore
import FirebaseStorage

// MARK: - Firestore

extension Query {
    func getDocumentsAsync() async throws -> QuerySnapshot {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<QuerySnapshot, Error>) in
            self.getDocuments { snap, err in
                if let err = err { cont.resume(throwing: err) }
                else if let snap = snap { cont.resume(returning: snap) }
                else {
                    cont.resume(throwing: NSError(
                        domain: "Firestore",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "nil QuerySnapshot"]
                    ))
                }
            }
        }
    }
}

extension DocumentReference {
    func setDataAsync(_ data: [String: Any], merge: Bool = false) async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            self.setData(data, merge: merge) { err in
                if let err = err { cont.resume(throwing: err) }
                else { cont.resume(returning: ()) }
            }
        }
    }
}

// MARK: - Storage

extension StorageReference {
    func putDataAsync(_ data: Foundation.Data, metadata: StorageMetadata?) async throws -> StorageMetadata {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<StorageMetadata, Error>) in
            self.putData(data, metadata: metadata) { meta, err in
                if let err = err { cont.resume(throwing: err) }
                else { cont.resume(returning: meta ?? StorageMetadata()) }
            }
        }
    }

    func downloadURLAsync() async throws -> URL {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<URL, Error>) in
            self.downloadURL { url, err in
                if let err = err { cont.resume(throwing: err) }
                else if let url = url { cont.resume(returning: url) }
                else {
                    cont.resume(throwing: NSError(
                        domain: "Storage",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "nil downloadURL"]
                    ))
                }
            }
        }
    }
}
