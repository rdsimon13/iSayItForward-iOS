//
//  SignatureStore.swift
//  iSIF_Beta
//

import Foundation
import FirebaseAuth
import FirebaseStorage

public enum SignatureStore {

    public static func save(imageData: Foundation.Data, for uid: String) async throws -> URL {
        let path = "users/\(uid)/signatures/latest.png"
        let ref = Storage.storage().reference().child(path)
        let meta = StorageMetadata()
        meta.contentType = "image/png"
        _ = try await ref.putDataAsync(imageData, metadata: meta)
        return try await ref.downloadURLAsync()
    }

    public static func loadLatestURL(for uid: String) async throws -> URL? {
        let ref = Storage.storage().reference().child("users/\(uid)/signatures/latest.png")
        do { return try await ref.downloadURLAsync() } catch { return nil }
    }
}
