import Foundation
import UniformTypeIdentifiers

// MARK: - Attachment Model
struct Attachment: Identifiable, Codable, Hashable, Equatable {
    let id: String
    let originalName: String
    let fileName: String // Unique filename for storage
    let fileSize: Int64
    let mimeType: String
    let fileExtension: String
    var localURL: URL? // Local cached file URL
    var remoteURL: String? // Firebase storage URL
    var thumbnailURL: String? // Thumbnail URL for images/videos
    let createdDate: Date
    var uploadProgress: Double = 0.0
    var isUploaded: Bool = false
    
    // Computed properties
    var displaySize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
    
    var fileType: AttachmentType {
        AttachmentType.fromMimeType(mimeType)
    }
    
    var systemImageName: String {
        fileType.systemImageName
    }
    
    init(id: String = UUID().uuidString,
         originalName: String,
         fileName: String,
         fileSize: Int64,
         mimeType: String,
         fileExtension: String,
         localURL: URL? = nil,
         remoteURL: String? = nil,
         thumbnailURL: String? = nil) {
        self.id = id
        self.originalName = originalName
        self.fileName = fileName
        self.fileSize = fileSize
        self.mimeType = mimeType
        self.fileExtension = fileExtension
        self.localURL = localURL
        self.remoteURL = remoteURL
        self.thumbnailURL = thumbnailURL
        self.createdDate = Date()
    }
    
    // Hashable & Equatable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Attachment, rhs: Attachment) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Attachment Type Enum
enum AttachmentType: String, CaseIterable, Codable {
    case image = "image"
    case video = "video"
    case document = "document"
    case audio = "audio"
    case unknown = "unknown"
    
    var displayName: String {
        switch self {
        case .image: return "Image"
        case .video: return "Video"
        case .document: return "Document"
        case .audio: return "Audio"
        case .unknown: return "File"
        }
    }
    
    var systemImageName: String {
        switch self {
        case .image: return "photo"
        case .video: return "video"
        case .document: return "doc.text"
        case .audio: return "waveform"
        case .unknown: return "doc"
        }
    }
    
    var maxFileSize: Int64 {
        switch self {
        case .image: return 10 * 1024 * 1024 // 10MB
        case .video: return 100 * 1024 * 1024 // 100MB
        case .document: return 25 * 1024 * 1024 // 25MB
        case .audio: return 50 * 1024 * 1024 // 50MB
        case .unknown: return 25 * 1024 * 1024 // 25MB
        }
    }
    
    static func fromMimeType(_ mimeType: String) -> AttachmentType {
        if mimeType.hasPrefix("image/") {
            return .image
        } else if mimeType.hasPrefix("video/") {
            return .video
        } else if mimeType.hasPrefix("audio/") {
            return .audio
        } else if mimeType.contains("pdf") || 
                  mimeType.contains("document") || 
                  mimeType.contains("text") ||
                  mimeType.contains("word") ||
                  mimeType.contains("excel") ||
                  mimeType.contains("powerpoint") {
            return .document
        } else {
            return .unknown
        }
    }
    
    static func fromFileExtension(_ ext: String) -> AttachmentType {
        let lowercased = ext.lowercased()
        
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "webp", "heic", "heif"]
        let videoExtensions = ["mp4", "mov", "avi", "mkv", "wmv", "flv", "webm", "m4v"]
        let audioExtensions = ["mp3", "wav", "aac", "flac", "ogg", "m4a", "wma"]
        let documentExtensions = ["pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "txt", "rtf"]
        
        if imageExtensions.contains(lowercased) {
            return .image
        } else if videoExtensions.contains(lowercased) {
            return .video
        } else if audioExtensions.contains(lowercased) {
            return .audio
        } else if documentExtensions.contains(lowercased) {
            return .document
        } else {
            return .unknown
        }
    }
}

// MARK: - Attachment Upload Status
enum AttachmentUploadStatus {
    case pending
    case uploading(progress: Double)
    case completed
    case failed(error: Error)
    
    var isCompleted: Bool {
        if case .completed = self {
            return true
        }
        return false
    }
    
    var isFailed: Bool {
        if case .failed = self {
            return true
        }
        return false
    }
    
    var progress: Double {
        if case .uploading(let progress) = self {
            return progress
        }
        return isCompleted ? 1.0 : 0.0
    }
}