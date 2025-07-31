import Foundation
import UIKit
import SwiftUI
import FirebaseStorage
import FirebaseAuth
import Combine

/// Main manager class for handling all content operations
@MainActor
class ContentManager: ObservableObject {
    static let shared = ContentManager()
    
    @Published var uploadProgress: [UUID: Double] = [:]
    @Published var isUploading: Bool = false
    @Published var error: ContentError?
    
    private let storage = Storage.storage()
    private let contentCache = ContentCache.shared
    private let compressionService = ContentCompressionService.shared
    private var uploadTasks: [UUID: StorageUploadTask] = [:]
    
    private init() {}
    
    /// Creates a ContentItem from a local file URL
    func createContentItem(from url: URL) async throws -> ContentItem {
        return try await ContentItem.from(url: url)
    }
    
    /// Uploads content to Firebase Storage
    func uploadContent(_ contentItem: ContentItem) async throws -> ContentItem {
        guard let user = Auth.auth().currentUser else {
            throw ContentError.uploadFailed("User not authenticated")
        }
        
        guard let localURL = contentItem.localURL else {
            throw ContentError.fileNotFound
        }
        
        var updatedItem = contentItem
        
        // Compress file if needed
        let fileToUpload: URL
        if shouldCompress(contentItem) {
            fileToUpload = try await compressionService.compressFile(at: localURL, mediaType: contentItem.mediaType)
        } else {
            fileToUpload = localURL
        }
        
        // Create storage reference
        let storagePath = "content/\(user.uid)/\(contentItem.id.uuidString)/\(contentItem.fileName)"
        let storageRef = storage.reference().child(storagePath)
        
        // Upload file
        let metadata = StorageMetadata()
        metadata.contentType = contentItem.mimeType
        
        return try await withCheckedThrowingContinuation { continuation in
            let uploadTask = storageRef.putFile(from: fileToUpload, metadata: metadata) { [weak self] metadata, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.error = .uploadFailed(error.localizedDescription)
                        continuation.resume(throwing: ContentError.uploadFailed(error.localizedDescription))
                    } else {
                        updatedItem.firebaseStoragePath = storagePath
                        updatedItem.isUploaded = true
                        updatedItem.uploadProgress = 1.0
                        
                        // Cache the uploaded content
                        Task {
                            await self?.contentCache.cacheContent(updatedItem)
                        }
                        
                        continuation.resume(returning: updatedItem)
                    }
                    
                    self?.uploadTasks.removeValue(forKey: contentItem.id)
                    self?.updateUploadingState()
                }
            }
            
            // Track upload progress
            uploadTask.observe(.progress) { [weak self] snapshot in
                DispatchQueue.main.async {
                    let progress = Double(snapshot.progress?.completedUnitCount ?? 0) / Double(snapshot.progress?.totalUnitCount ?? 1)
                    self?.uploadProgress[contentItem.id] = progress
                    updatedItem.uploadProgress = progress
                }
            }
            
            uploadTasks[contentItem.id] = uploadTask
            updateUploadingState()
        }
    }
    
    /// Downloads content from Firebase Storage
    func downloadContent(_ contentItem: ContentItem) async throws -> URL {
        guard let storagePath = contentItem.firebaseStoragePath else {
            throw ContentError.fileNotFound
        }
        
        // Check cache first
        if let cachedURL = await contentCache.getCachedContentURL(for: contentItem.id) {
            return cachedURL
        }
        
        let storageRef = storage.reference().child(storagePath)
        
        // Create local file URL
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let localURL = documentsPath.appendingPathComponent("downloads").appendingPathComponent(contentItem.fileName)
        
        // Create downloads directory if needed
        try FileManager.default.createDirectory(at: localURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        
        return try await withCheckedThrowingContinuation { continuation in
            let downloadTask = storageRef.write(toFile: localURL) { [weak self] url, error in
                if let error = error {
                    continuation.resume(throwing: ContentError.uploadFailed(error.localizedDescription))
                } else if let url = url {
                    // Cache the downloaded content
                    Task {
                        var cachedItem = contentItem
                        cachedItem.localURL = url
                        await self?.contentCache.cacheContent(cachedItem)
                    }
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(throwing: ContentError.fileNotFound)
                }
            }
        }
    }
    
    /// Cancels an upload operation
    func cancelUpload(for contentId: UUID) {
        uploadTasks[contentId]?.cancel()
        uploadTasks.removeValue(forKey: contentId)
        uploadProgress.removeValue(forKey: contentId)
        updateUploadingState()
    }
    
    /// Deletes content from Firebase Storage
    func deleteContent(_ contentItem: ContentItem) async throws {
        guard let storagePath = contentItem.firebaseStoragePath else {
            return // Nothing to delete if not uploaded
        }
        
        let storageRef = storage.reference().child(storagePath)
        
        try await withCheckedThrowingContinuation { continuation in
            storageRef.delete { error in
                if let error = error {
                    continuation.resume(throwing: ContentError.uploadFailed(error.localizedDescription))
                } else {
                    Task {
                        await self.contentCache.removeCachedContent(for: contentItem.id)
                    }
                    continuation.resume()
                }
            }
        }
    }
    
    /// Generates a thumbnail for visual content
    func generateThumbnail(for contentItem: ContentItem) async -> UIImage? {
        guard contentItem.mediaType == .photo || contentItem.mediaType == .video else {
            return nil
        }
        
        guard let localURL = contentItem.localURL else {
            return nil
        }
        
        switch contentItem.mediaType {
        case .photo:
            return UIImage(contentsOfFile: localURL.path)
        case .video:
            // Video thumbnail generation would require AVFoundation
            return nil
        default:
            return nil
        }
    }
    
    /// Clears all cached content
    func clearCache() async {
        await contentCache.clearCache()
    }
    
    // MARK: - Private Methods
    
    private func shouldCompress(_ contentItem: ContentItem) -> Bool {
        // Compress photos larger than 10MB or videos larger than 100MB
        switch contentItem.mediaType {
        case .photo:
            return contentItem.fileSize > 10_000_000
        case .video:
            return contentItem.fileSize > 100_000_000
        default:
            return false
        }
    }
    
    private func updateUploadingState() {
        isUploading = !uploadTasks.isEmpty
    }
}