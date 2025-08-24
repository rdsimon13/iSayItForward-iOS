import Foundation
import UIKit

/// Represents a piece of content (media, text, etc.) that can be attached to a SIF
struct ContentItem: Identifiable, Codable, Hashable {
    let id = UUID()
    let fileName: String
    let originalFileName: String
    let mediaType: MediaType
    let fileSize: Int64
    let mimeType: String
    let createdDate: Date
    var uploadProgress: Double = 0.0
    var isUploaded: Bool = false
    var firebaseStoragePath: String?
    var localURL: URL?
    var thumbnailURL: URL?
    
    // Rich text content for text type
    var textContent: String?
    
    // Duration for audio/video content
    var duration: TimeInterval?
    
    // Dimensions for photo/video content
    var width: Int?
    var height: Int?
    
    init(fileName: String, originalFileName: String, mediaType: MediaType, fileSize: Int64, mimeType: String, localURL: URL? = nil) {
        self.fileName = fileName
        self.originalFileName = originalFileName
        self.mediaType = mediaType
        self.fileSize = fileSize
        self.mimeType = mimeType
        self.createdDate = Date()
        self.localURL = localURL
    }
    
    /// Creates a ContentItem from a local file URL
    static func from(url: URL) async throws -> ContentItem {
        let fileAttributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let fileSize = fileAttributes[.size] as? Int64 ?? 0
        
        let fileName = url.lastPathComponent
        let fileExtension = url.pathExtension
        
        guard let mediaType = MediaType.from(fileExtension: fileExtension) else {
            throw ContentError.unsupportedFileType
        }
        
        // Check file size limit
        if fileSize > mediaType.maxFileSize {
            throw ContentError.fileTooLarge(maxSize: mediaType.maxFileSize)
        }
        
        let mimeType = await getMimeType(for: url)
        
        var contentItem = ContentItem(
            fileName: fileName,
            originalFileName: fileName,
            mediaType: mediaType,
            fileSize: fileSize,
            mimeType: mimeType,
            localURL: url
        )
        
        // Extract additional metadata based on media type
        switch mediaType {
        case .photo:
            if let image = UIImage(contentsOfFile: url.path) {
                contentItem.width = Int(image.size.width)
                contentItem.height = Int(image.size.height)
            }
        case .text:
            if let textContent = try? String(contentsOf: url) {
                contentItem.textContent = textContent
            }
        case .audio, .video:
            // Duration extraction would require AVFoundation
            break
        case .document:
            break
        }
        
        return contentItem
    }
    
    /// Gets the display name for the content
    var displayName: String {
        return originalFileName
    }
    
    /// Gets a formatted file size string
    var formattedFileSize: String {
        return ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
    
    /// Checks if the content item has a local file
    var hasLocalFile: Bool {
        guard let localURL = localURL else { return false }
        return FileManager.default.fileExists(atPath: localURL.path)
    }
    
    /// Gets the download URL for the content if uploaded
    var downloadURL: URL? {
        guard let path = firebaseStoragePath else { return nil }
        // This would be constructed from Firebase Storage reference
        return URL(string: "gs://bucket/\(path)")
    }
}

// MARK: - Helper Functions
private func getMimeType(for url: URL) async -> String {
    if #available(iOS 14.0, *) {
        if let utType = UTType(filenameExtension: url.pathExtension) {
            return utType.preferredMIMEType ?? "application/octet-stream"
        }
    }
    
    // Fallback for older iOS versions
    let fileExtension = url.pathExtension.lowercased()
    switch fileExtension {
    case "jpg", "jpeg":
        return "image/jpeg"
    case "png":
        return "image/png"
    case "pdf":
        return "application/pdf"
    case "mp4":
        return "video/mp4"
    case "m4a":
        return "audio/mp4"
    case "txt":
        return "text/plain"
    default:
        return "application/octet-stream"
    }
}

// MARK: - Content Errors
enum ContentError: LocalizedError {
    case unsupportedFileType
    case fileTooLarge(maxSize: Int64)
    case fileNotFound
    case uploadFailed(String)
    case compressionFailed
    case invalidContent
    
    var errorDescription: String? {
        switch self {
        case .unsupportedFileType:
            return "This file type is not supported"
        case .fileTooLarge(let maxSize):
            let formattedSize = ByteCountFormatter.string(fromByteCount: maxSize, countStyle: .file)
            return "File is too large. Maximum size is \(formattedSize)"
        case .fileNotFound:
            return "File could not be found"
        case .uploadFailed(let message):
            return "Upload failed: \(message)"
        case .compressionFailed:
            return "Failed to compress file"
        case .invalidContent:
            return "Invalid content data"
        }
    }
}