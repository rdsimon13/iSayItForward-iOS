import Foundation
import UIKit
import UniformTypeIdentifiers
import Combine
import Photos
import AVFoundation

// MARK: - Attachment Manager Error Types
enum AttachmentManagerError: LocalizedError {
    case fileTooLarge(maxSize: Int64)
    case unsupportedFileType
    case fileNotFound
    case compressionFailed
    case uploadFailed(underlying: Error)
    case permissionDenied
    case invalidFile
    
    var errorDescription: String? {
        switch self {
        case .fileTooLarge(let maxSize):
            return "File is too large. Maximum size is \(ByteCountFormatter.string(fromByteCount: maxSize, countStyle: .file))"
        case .unsupportedFileType:
            return "File type is not supported"
        case .fileNotFound:
            return "File not found"
        case .compressionFailed:
            return "Failed to compress file"
        case .uploadFailed(let error):
            return "Upload failed: \(error.localizedDescription)"
        case .permissionDenied:
            return "Permission denied to access file"
        case .invalidFile:
            return "Invalid file"
        }
    }
}

// MARK: - Attachment Manager
@MainActor
class AttachmentManager: ObservableObject {
    static let shared = AttachmentManager()
    
    @Published var uploadQueue: [Attachment] = []
    @Published var uploadStatuses: [String: AttachmentUploadStatus] = [:]
    
    private let fileManager = FileManager.default
    private let documentsDirectory: URL
    private let cacheDirectory: URL
    private let thumbnailDirectory: URL
    
    // Upload settings
    private let maxConcurrentUploads = 3
    private let compressionQuality: CGFloat = 0.8
    
    private init() {
        // Setup directories
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        documentsDirectory = documentsPath.appendingPathComponent("Attachments")
        cacheDirectory = documentsPath.appendingPathComponent("AttachmentCache")
        thumbnailDirectory = documentsPath.appendingPathComponent("Thumbnails")
        
        createDirectoriesIfNeeded()
    }
    
    // MARK: - Directory Management
    private func createDirectoriesIfNeeded() {
        let directories = [documentsDirectory, cacheDirectory, thumbnailDirectory]
        
        for directory in directories {
            if !fileManager.fileExists(atPath: directory.path) {
                try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            }
        }
    }
    
    // MARK: - File Validation
    func validateFile(at url: URL) throws -> (size: Int64, mimeType: String, fileExtension: String) {
        guard fileManager.fileExists(atPath: url.path) else {
            throw AttachmentManagerError.fileNotFound
        }
        
        let attributes = try fileManager.attributesOfItem(atPath: url.path)
        let fileSize = attributes[.size] as? Int64 ?? 0
        
        let fileExtension = url.pathExtension.lowercased()
        let attachmentType = AttachmentType.fromFileExtension(fileExtension)
        
        // Validate file size
        if fileSize > attachmentType.maxFileSize {
            throw AttachmentManagerError.fileTooLarge(maxSize: attachmentType.maxFileSize)
        }
        
        // Get MIME type
        let mimeType = getMimeType(for: url)
        
        return (fileSize, mimeType, fileExtension)
    }
    
    private func getMimeType(for url: URL) -> String {
        if let uti = UTType(filenameExtension: url.pathExtension) {
            return uti.preferredMIMEType ?? "application/octet-stream"
        }
        return "application/octet-stream"
    }
    
    // MARK: - File Processing
    func processFile(from sourceURL: URL, originalName: String) async throws -> Attachment {
        let validation = try validateFile(at: sourceURL)
        
        let attachment = Attachment(
            originalName: originalName,
            fileName: "\(UUID().uuidString).\(validation.fileExtension)",
            fileSize: validation.size,
            mimeType: validation.mimeType,
            fileExtension: validation.fileExtension
        )
        
        // Copy file to cache directory
        let cachedURL = cacheDirectory.appendingPathComponent(attachment.fileName)
        
        if fileManager.fileExists(atPath: cachedURL.path) {
            try fileManager.removeItem(at: cachedURL)
        }
        
        var processedURL = sourceURL
        
        // Compress if needed
        if attachment.fileType == .image {
            processedURL = try await compressImage(at: sourceURL, attachment: attachment)
        } else if attachment.fileType == .video {
            processedURL = try await compressVideo(at: sourceURL, attachment: attachment)
        }
        
        try fileManager.copyItem(at: processedURL, to: cachedURL)
        
        var updatedAttachment = attachment
        updatedAttachment.localURL = cachedURL
        
        // Generate thumbnail
        if let thumbnailURL = try await generateThumbnail(for: updatedAttachment) {
            updatedAttachment.thumbnailURL = thumbnailURL.absoluteString
        }
        
        return updatedAttachment
    }
    
    // MARK: - Compression
    private func compressImage(at url: URL, attachment: Attachment) async throws -> URL {
        guard let image = UIImage(contentsOfFile: url.path) else {
            throw AttachmentManagerError.compressionFailed
        }
        
        // Calculate target size to keep under size limit
        let targetSize = min(1920, max(image.size.width, image.size.height))
        let resizedImage = resizeImage(image, targetSize: targetSize)
        
        guard let imageData = resizedImage.jpegData(compressionQuality: compressionQuality) else {
            throw AttachmentManagerError.compressionFailed
        }
        
        let compressedURL = cacheDirectory.appendingPathComponent("compressed_\(attachment.fileName)")
        try imageData.write(to: compressedURL)
        
        return compressedURL
    }
    
    private func compressVideo(at url: URL, attachment: Attachment) async throws -> URL {
        // For now, return original URL - video compression is complex
        // In a full implementation, you'd use AVAssetExportSession
        return url
    }
    
    private func resizeImage(_ image: UIImage, targetSize: CGFloat) -> UIImage {
        let size = image.size
        let aspectRatio = size.width / size.height
        
        var newWidth: CGFloat
        var newHeight: CGFloat
        
        if aspectRatio > 1 {
            newWidth = targetSize
            newHeight = targetSize / aspectRatio
        } else {
            newHeight = targetSize
            newWidth = targetSize * aspectRatio
        }
        
        let rect = CGRect(x: 0, y: 0, width: newWidth, height: newHeight)
        
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 1.0)
        image.draw(in: rect)
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage ?? image
    }
    
    // MARK: - Thumbnail Generation
    func generateThumbnail(for attachment: Attachment) async throws -> URL? {
        guard let localURL = attachment.localURL else { return nil }
        
        let thumbnailURL = thumbnailDirectory.appendingPathComponent("thumb_\(attachment.fileName)")
        
        switch attachment.fileType {
        case .image:
            return try generateImageThumbnail(from: localURL, to: thumbnailURL)
        case .video:
            return try await generateVideoThumbnail(from: localURL, to: thumbnailURL)
        default:
            return nil
        }
    }
    
    private func generateImageThumbnail(from sourceURL: URL, to thumbnailURL: URL) throws -> URL {
        guard let image = UIImage(contentsOfFile: sourceURL.path) else {
            throw AttachmentManagerError.compressionFailed
        }
        
        let thumbnailImage = resizeImage(image, targetSize: 150)
        guard let thumbnailData = thumbnailImage.jpegData(compressionQuality: 0.7) else {
            throw AttachmentManagerError.compressionFailed
        }
        
        try thumbnailData.write(to: thumbnailURL)
        return thumbnailURL
    }
    
    private func generateVideoThumbnail(from sourceURL: URL, to thumbnailURL: URL) async throws -> URL {
        let asset = AVAsset(url: sourceURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        let time = CMTime(seconds: 1, preferredTimescale: 60)
        
        return try await withCheckedThrowingContinuation { continuation in
            imageGenerator.generateCGImageAsynchronously(for: time) { cgImage, _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let cgImage = cgImage else {
                    continuation.resume(throwing: AttachmentManagerError.compressionFailed)
                    return
                }
                
                let image = UIImage(cgImage: cgImage)
                let thumbnailImage = self.resizeImage(image, targetSize: 150)
                
                guard let thumbnailData = thumbnailImage.jpegData(compressionQuality: 0.7) else {
                    continuation.resume(throwing: AttachmentManagerError.compressionFailed)
                    return
                }
                
                do {
                    try thumbnailData.write(to: thumbnailURL)
                    continuation.resume(returning: thumbnailURL)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Upload Queue Management
    func addToUploadQueue(_ attachment: Attachment) {
        uploadQueue.append(attachment)
        uploadStatuses[attachment.id] = .pending
    }
    
    func removeFromUploadQueue(_ attachmentId: String) {
        uploadQueue.removeAll { $0.id == attachmentId }
        uploadStatuses.removeValue(forKey: attachmentId)
    }
    
    func updateUploadStatus(_ attachmentId: String, status: AttachmentUploadStatus) {
        uploadStatuses[attachmentId] = status
    }
    
    // MARK: - Cache Management
    func clearCache() throws {
        let cacheContents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
        for url in cacheContents {
            try fileManager.removeItem(at: url)
        }
        
        let thumbnailContents = try fileManager.contentsOfDirectory(at: thumbnailDirectory, includingPropertiesForKeys: nil)
        for url in thumbnailContents {
            try fileManager.removeItem(at: url)
        }
    }
    
    func getCacheSize() -> Int64 {
        var totalSize: Int64 = 0
        
        let directories = [cacheDirectory, thumbnailDirectory]
        for directory in directories {
            if let contents = try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.fileSizeKey]) {
                for url in contents {
                    if let attributes = try? fileManager.attributesOfItem(atPath: url.path),
                       let size = attributes[.size] as? Int64 {
                        totalSize += size
                    }
                }
            }
        }
        
        return totalSize
    }
    
    // MARK: - File Access
    func getLocalURL(for attachment: Attachment) -> URL? {
        guard let localURL = attachment.localURL,
              fileManager.fileExists(atPath: localURL.path) else {
            return nil
        }
        return localURL
    }
    
    func getThumbnailURL(for attachment: Attachment) -> URL? {
        guard let thumbnailPath = attachment.thumbnailURL else { return nil }
        let url = URL(string: thumbnailPath) ?? thumbnailDirectory.appendingPathComponent("thumb_\(attachment.fileName)")
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }
}