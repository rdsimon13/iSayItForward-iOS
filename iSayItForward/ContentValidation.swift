import Foundation
import UIKit
import AVFoundation

// MARK: - Content Validation Utilities
struct ContentValidation {
    
    // MARK: - File Size Validation
    static func validateFileSize(_ size: Int, for contentType: ContentType) -> ValidationResult {
        if size > contentType.maxSizeBytes {
            let maxSizeMB = contentType.maxSizeBytes / 1_000_000
            return .failure("File size exceeds the maximum allowed size of \(maxSizeMB)MB for \(contentType.displayName.lowercased()) content.")
        }
        return .success
    }
    
    // MARK: - File Extension Validation  
    static func validateFileExtension(_ fileName: String, for contentType: ContentType) -> ValidationResult {
        let fileExtension = (fileName as NSString).pathExtension.lowercased()
        if !contentType.allowedExtensions.contains(fileExtension) {
            let allowedExtensions = contentType.allowedExtensions.joined(separator: ", ")
            return .failure("File extension '\(fileExtension)' is not supported. Allowed extensions: \(allowedExtensions)")
        }
        return .success
    }
    
    // MARK: - Image Validation and Processing
    static func validateAndProcessImage(_ image: UIImage, fileName: String) -> ContentAttachment? {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            return nil
        }
        
        let fileSize = imageData.count
        let attachment = ContentAttachment(
            contentType: .photo,
            fileName: fileName,
            fileSize: fileSize,
            metadata: [
                "width": "\(Int(image.size.width))",
                "height": "\(Int(image.size.height))",
                "compressed": "true"
            ]
        )
        
        return attachment.isValidSize ? attachment : nil
    }
    
    // MARK: - Video Validation
    static func validateVideo(at url: URL) -> ValidationResult {
        let asset = AVAsset(url: url)
        
        // Check duration (max 10 minutes)
        let duration = asset.duration.seconds
        if duration > 600 { // 10 minutes
            return .failure("Video duration exceeds the maximum allowed length of 10 minutes.")
        }
        
        return .success
    }
    
    // MARK: - Audio Validation
    static func validateAudio(at url: URL) -> ValidationResult {
        let asset = AVAsset(url: url)
        
        // Check duration (max 30 minutes)
        let duration = asset.duration.seconds
        if duration > 1800 { // 30 minutes
            return .failure("Audio duration exceeds the maximum allowed length of 30 minutes.")
        }
        
        return .success
    }
    
    // MARK: - Generate Preview
    static func generatePreview(for attachment: ContentAttachment) -> PreviewData? {
        switch attachment.contentType {
        case .photo:
            return PhotoPreview(attachment: attachment)
        case .video:
            return VideoPreview(attachment: attachment)
        case .audio:
            return AudioPreview(attachment: attachment)
        case .document:
            return DocumentPreview(attachment: attachment)
        case .text:
            return TextPreview(attachment: attachment)
        }
    }
}

// MARK: - Validation Result
enum ValidationResult {
    case success
    case failure(String)
    
    var isValid: Bool {
        switch self {
        case .success: return true
        case .failure: return false
        }
    }
    
    var errorMessage: String? {
        switch self {
        case .success: return nil
        case .failure(let message): return message
        }
    }
}

// MARK: - Preview Data Protocol
protocol PreviewData {
    var attachment: ContentAttachment { get }
    var displayName: String { get }
    var displaySize: String { get }
    var previewImageName: String { get }
}

// MARK: - Preview Implementations
struct PhotoPreview: PreviewData {
    let attachment: ContentAttachment
    
    var displayName: String { attachment.fileName }
    var displaySize: String { ByteFormatter.format(bytes: attachment.fileSize) }
    var previewImageName: String { "photo" }
}

struct VideoPreview: PreviewData {
    let attachment: ContentAttachment
    
    var displayName: String { attachment.fileName }
    var displaySize: String { 
        let size = ByteFormatter.format(bytes: attachment.fileSize)
        if let duration = attachment.duration {
            let minutes = Int(duration) / 60
            let seconds = Int(duration) % 60
            return "\(size) • \(minutes):\(String(format: "%02d", seconds))"
        }
        return size
    }
    var previewImageName: String { "video" }
}

struct AudioPreview: PreviewData {
    let attachment: ContentAttachment
    
    var displayName: String { attachment.fileName }
    var displaySize: String {
        let size = ByteFormatter.format(bytes: attachment.fileSize)
        if let duration = attachment.duration {
            let minutes = Int(duration) / 60
            let seconds = Int(duration) % 60
            return "\(size) • \(minutes):\(String(format: "%02d", seconds))"
        }
        return size
    }
    var previewImageName: String { "mic" }
}

struct DocumentPreview: PreviewData {
    let attachment: ContentAttachment
    
    var displayName: String { attachment.fileName }
    var displaySize: String { ByteFormatter.format(bytes: attachment.fileSize) }
    var previewImageName: String { "doc.text" }
}

struct TextPreview: PreviewData {
    let attachment: ContentAttachment
    
    var displayName: String { attachment.fileName }
    var displaySize: String { ByteFormatter.format(bytes: attachment.fileSize) }
    var previewImageName: String { "doc.plaintext" }
}

// MARK: - Byte Formatter Utility
struct ByteFormatter {
    static func format(bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}