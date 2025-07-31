import Foundation
import FirebaseFirestore

// MARK: - Content Type Definitions
enum ContentType: String, Codable, CaseIterable {
    case text = "text"
    case audio = "audio" 
    case photo = "photo"
    case video = "video"
    case document = "document"
    
    var displayName: String {
        switch self {
        case .text: return "Text"
        case .audio: return "Audio"
        case .photo: return "Photo"
        case .video: return "Video"
        case .document: return "Document"
        }
    }
    
    var maxSizeBytes: Int {
        switch self {
        case .text: return 1_000_000 // 1MB
        case .audio: return 25_000_000 // 25MB
        case .photo: return 10_000_000 // 10MB
        case .video: return 100_000_000 // 100MB
        case .document: return 50_000_000 // 50MB
        }
    }
    
    var allowedExtensions: [String] {
        switch self {
        case .text: return ["txt", "rtf"]
        case .audio: return ["mp3", "m4a", "wav", "aac"]
        case .photo: return ["jpg", "jpeg", "png", "heic", "gif"]
        case .video: return ["mp4", "mov", "avi", "m4v"]
        case .document: return ["pdf", "doc", "docx", "pages"]
        }
    }
}

// MARK: - Content Attachment Model
struct ContentAttachment: Identifiable, Codable, Hashable, Equatable {
    let id: UUID
    let contentType: ContentType
    let fileName: String
    let fileSize: Int
    let url: String? // Firebase Storage URL
    let localURL: String? // Local file path during upload
    let thumbnailURL: String? // For images and videos
    let duration: TimeInterval? // For audio and video
    let metadata: [String: String] // Additional metadata
    let createdDate: Date
    
    init(contentType: ContentType, fileName: String, fileSize: Int, localURL: String? = nil, metadata: [String: String] = [:]) {
        self.id = UUID()
        self.contentType = contentType
        self.fileName = fileName
        self.fileSize = fileSize
        self.url = nil
        self.localURL = localURL
        self.thumbnailURL = nil
        self.duration = nil
        self.metadata = metadata
        self.createdDate = Date()
    }
    
    // Validate file size against content type limits
    var isValidSize: Bool {
        return fileSize <= contentType.maxSizeBytes
    }
    
    // Validate file extension
    var isValidExtension: Bool {
        let fileExtension = (fileName as NSString).pathExtension.lowercased()
        return contentType.allowedExtensions.contains(fileExtension)
    }
}

// This is the new, correct data model for a SIF.
// Codable allows it to be easily saved to and loaded from Firestore.
struct SIFItem: Identifiable, Codable, Hashable, Equatable {
    // This property will automatically be managed by Firestore
    @DocumentID var id: String?
    
    let authorUid: String
    var recipients: [String]
    var subject: String
    var message: String
    let createdDate: Date
    var scheduledDate: Date
    
    // Enhanced content support
    var contentAttachments: [ContentAttachment] = []
    var templateName: String? = nil
    var templateCategory: String? = nil
    var contentMetadata: [String: String] = [:]
    
    // Legacy support - keep for backward compatibility
    var attachmentURL: String? = nil
    
    // MARK: - Initializers
    init(authorUid: String, recipients: [String], subject: String, message: String, createdDate: Date, scheduledDate: Date, contentAttachments: [ContentAttachment] = [], templateName: String? = nil, templateCategory: String? = nil, contentMetadata: [String: String] = [:]) {
        self.authorUid = authorUid
        self.recipients = recipients
        self.subject = subject
        self.message = message
        self.createdDate = createdDate
        self.scheduledDate = scheduledDate
        self.contentAttachments = contentAttachments
        self.templateName = templateName
        self.templateCategory = templateCategory
        self.contentMetadata = contentMetadata
    }
    
    // MARK: - Content Helper Methods
    
    // Get attachments by content type
    func attachments(of type: ContentType) -> [ContentAttachment] {
        return contentAttachments.filter { $0.contentType == type }
    }
    
    // Check if SIF has any attachments
    var hasAttachments: Bool {
        return !contentAttachments.isEmpty
    }
    
    // Get total size of all attachments
    var totalAttachmentSize: Int {
        return contentAttachments.reduce(0) { $0 + $1.fileSize }
    }
    
    // Validate all attachments
    var hasValidAttachments: Bool {
        return contentAttachments.allSatisfy { $0.isValidSize && $0.isValidExtension }
    }
    
    // MARK: - Hashable & Equatable conformance for SwiftUI lists
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: SIFItem, rhs: SIFItem) -> Bool {
        lhs.id == rhs.id
    }
}
