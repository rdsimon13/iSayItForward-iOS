import Foundation
import UIKit
import UniformTypeIdentifiers

/// Enum representing different types of media content supported by the app
enum MediaType: String, CaseIterable, Codable {
    case text = "text"
    case audio = "audio"
    case photo = "photo"
    case video = "video"
    case document = "document"
    
    /// Display name for the media type
    var displayName: String {
        switch self {
        case .text:
            return "Text"
        case .audio:
            return "Audio"
        case .photo:
            return "Photo"
        case .video:
            return "Video"
        case .document:
            return "Document"
        }
    }
    
    /// System icon name for the media type
    var iconName: String {
        switch self {
        case .text:
            return "text.alignleft"
        case .audio:
            return "mic.circle.fill"
        case .photo:
            return "photo"
        case .video:
            return "video"
        case .document:
            return "doc.text"
        }
    }
    
    /// Supported file extensions for each media type
    var supportedExtensions: [String] {
        switch self {
        case .text:
            return ["txt", "rtf"]
        case .audio:
            return ["mp3", "m4a", "wav", "aac"]
        case .photo:
            return ["jpg", "jpeg", "png", "heic", "gif"]
        case .video:
            return ["mp4", "mov", "avi", "m4v"]
        case .document:
            return ["pdf", "doc", "docx", "ppt", "pptx", "xls", "xlsx"]
        }
    }
    
    /// Maximum file size in bytes for each media type
    var maxFileSize: Int64 {
        switch self {
        case .text:
            return 1_000_000 // 1MB
        case .audio:
            return 50_000_000 // 50MB
        case .photo:
            return 25_000_000 // 25MB
        case .video:
            return 500_000_000 // 500MB
        case .document:
            return 100_000_000 // 100MB
        }
    }
    
    /// Determines media type from file extension
    static func from(fileExtension: String) -> MediaType? {
        let lowercased = fileExtension.lowercased()
        
        for mediaType in MediaType.allCases {
            if mediaType.supportedExtensions.contains(lowercased) {
                return mediaType
            }
        }
        return nil
    }
    
    /// Determines media type from MIME type
    static func from(mimeType: String) -> MediaType? {
        let lowercased = mimeType.lowercased()
        
        if lowercased.hasPrefix("text/") {
            return .text
        } else if lowercased.hasPrefix("audio/") {
            return .audio
        } else if lowercased.hasPrefix("image/") {
            return .photo
        } else if lowercased.hasPrefix("video/") {
            return .video
        } else if lowercased.contains("pdf") || 
                  lowercased.contains("msword") || 
                  lowercased.contains("spreadsheet") ||
                  lowercased.contains("presentation") {
            return .document
        }
        
        return nil
    }
    
    /// Gets UTType for the media type
    var utType: UTType {
        switch self {
        case .text:
            if #available(iOS 14.0, *) {
                return .text
            } else {
                return UTType("public.text")!
            }
        case .audio:
            if #available(iOS 14.0, *) {
                return .audio
            } else {
                return UTType("public.audio")!
            }
        case .photo:
            if #available(iOS 14.0, *) {
                return .image
            } else {
                return UTType("public.image")!
            }
        case .video:
            if #available(iOS 14.0, *) {
                return .movie
            } else {
                return UTType("public.movie")!
            }
        case .document:
            if #available(iOS 14.0, *) {
                return .data
            } else {
                return UTType("public.data")!
            }
        }
    }
}