import Foundation
import FirebaseStorage
import FirebaseAuth
import UIKit
import UniformTypeIdentifiers
import Combine

// Service responsible for content management, file uploads, and media handling
class ContentManagementService: ObservableObject {
    static let shared = ContentManagementService()
    
    @Published var uploadProgress: [String: Double] = [:]
    @Published var activeUploads: Set<String> = []
    @Published var uploadedFiles: [UploadedFile] = []
    
    private let storage = Storage.storage()
    private let maxFileSize: Int64 = 100 * 1024 * 1024 // 100MB
    private let chunkSize: Int64 = 1024 * 1024 // 1MB chunks
    private var uploadTasks: [String: StorageUploadTask] = [:]
    
    private init() {}
    
    // MARK: - File Upload
    
    /// Uploads a file and returns the download URL
    func uploadFile(_ fileURL: URL, to path: String, sifId: String) async throws -> UploadedFile {
        let fileId = UUID().uuidString
        let fileName = fileURL.lastPathComponent
        let fileExtension = fileURL.pathExtension.lowercased()
        
        // Validate file
        try validateFile(at: fileURL)
        
        // Start upload tracking
        await updateUploadProgress(fileId: fileId, progress: 0.0)
        activeUploads.insert(fileId)
        
        defer {
            activeUploads.remove(fileId)
            uploadProgress.removeValue(forKey: fileId)
            uploadTasks.removeValue(forKey: fileId)
        }
        
        do {
            let fileData = try Data(contentsOf: fileURL)
            let fileSize = Int64(fileData.count)
            
            // Determine upload strategy based on file size
            let downloadURL: URL
            if fileSize > chunkSize {
                downloadURL = try await uploadLargeFile(data: fileData, fileName: fileName, path: path, fileId: fileId)
            } else {
                downloadURL = try await uploadSmallFile(data: fileData, fileName: fileName, path: path, fileId: fileId)
            }
            
            // Create file metadata
            let uploadedFile = UploadedFile(
                id: fileId,
                name: fileName,
                url: downloadURL.absoluteString,
                size: fileSize,
                type: getFileType(for: fileExtension),
                mimeType: getMimeType(for: fileExtension),
                uploadDate: Date(),
                sifId: sifId
            )
            
            // Store file metadata
            try await saveFileMetadata(uploadedFile)
            
            DispatchQueue.main.async {
                self.uploadedFiles.append(uploadedFile)
            }
            
            return uploadedFile
            
        } catch {
            throw ContentManagementError.uploadFailed(error.localizedDescription)
        }
    }
    
    /// Uploads multiple files
    func uploadFiles(_ fileURLs: [URL], sifId: String) async throws -> [UploadedFile] {
        var uploadedFiles: [UploadedFile] = []
        
        for (index, fileURL) in fileURLs.enumerated() {
            let path = "sifs/\(sifId)/attachments/\(index)_\(fileURL.lastPathComponent)"
            let uploadedFile = try await uploadFile(fileURL, to: path, sifId: sifId)
            uploadedFiles.append(uploadedFile)
        }
        
        return uploadedFiles
    }
    
    private func uploadSmallFile(data: Data, fileName: String, path: String, fileId: String) async throws -> URL {
        let storageRef = storage.reference().child(path)
        
        return try await withCheckedThrowingContinuation { continuation in
            let uploadTask = storageRef.putData(data, metadata: nil) { metadata, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                storageRef.downloadURL { url, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let url = url {
                        continuation.resume(returning: url)
                    } else {
                        continuation.resume(throwing: ContentManagementError.uploadFailed("Unknown error"))
                    }
                }
            }
            
            // Track progress
            uploadTask.observe(.progress) { [weak self] snapshot in
                guard let progress = snapshot.progress else { return }
                let progressValue = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
                Task {
                    await self?.updateUploadProgress(fileId: fileId, progress: progressValue)
                }
            }
            
            uploadTasks[fileId] = uploadTask
        }
    }
    
    private func uploadLargeFile(data: Data, fileName: String, path: String, fileId: String) async throws -> URL {
        let storageRef = storage.reference().child(path)
        
        // Use resumable upload for large files
        return try await withCheckedThrowingContinuation { continuation in
            let metadata = StorageMetadata()
            metadata.contentType = getMimeType(for: URL(fileURLWithPath: fileName).pathExtension)
            
            let uploadTask = storageRef.putData(data, metadata: metadata) { metadata, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                storageRef.downloadURL { url, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let url = url {
                        continuation.resume(returning: url)
                    } else {
                        continuation.resume(throwing: ContentManagementError.uploadFailed("Unknown error"))
                    }
                }
            }
            
            // Track progress
            uploadTask.observe(.progress) { [weak self] snapshot in
                guard let progress = snapshot.progress else { return }
                let progressValue = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
                Task {
                    await self?.updateUploadProgress(fileId: fileId, progress: progressValue)
                }
            }
            
            uploadTasks[fileId] = uploadTask
        }
    }
    
    // MARK: - File Management
    
    /// Cancels an ongoing upload
    func cancelUpload(fileId: String) {
        uploadTasks[fileId]?.cancel()
        uploadTasks.removeValue(forKey: fileId)
        activeUploads.remove(fileId)
        uploadProgress.removeValue(forKey: fileId)
    }
    
    /// Pauses an upload
    func pauseUpload(fileId: String) {
        uploadTasks[fileId]?.pause()
    }
    
    /// Resumes a paused upload
    func resumeUpload(fileId: String) {
        uploadTasks[fileId]?.resume()
    }
    
    /// Deletes a file from storage
    func deleteFile(_ file: UploadedFile) async throws {
        let storageRef = storage.reference().child(file.url)
        try await storageRef.delete()
        
        // Remove from metadata
        try await deleteFileMetadata(file.id)
        
        DispatchQueue.main.async {
            self.uploadedFiles.removeAll { $0.id == file.id }
        }
    }
    
    /// Gets file metadata for a SIF
    func getFilesForSIF(_ sifId: String) async throws -> [UploadedFile] {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw ContentManagementError.authenticationRequired
        }
        
        let snapshot = try await Firestore.firestore()
            .collection("users").document(userId)
            .collection("files")
            .whereField("sifId", isEqualTo: sifId)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: UploadedFile.self)
        }
    }
    
    // MARK: - File Validation
    
    private func validateFile(at url: URL) throws {
        let fileManager = FileManager.default
        
        // Check if file exists
        guard fileManager.fileExists(atPath: url.path) else {
            throw ContentManagementError.fileNotFound
        }
        
        // Check file size
        let attributes = try fileManager.attributesOfItem(atPath: url.path)
        let fileSize = attributes[.size] as? Int64 ?? 0
        
        guard fileSize <= maxFileSize else {
            throw ContentManagementError.fileTooLarge
        }
        
        // Check file type
        let fileExtension = url.pathExtension.lowercased()
        guard isFileTypeSupported(fileExtension) else {
            throw ContentManagementError.unsupportedFileType
        }
    }
    
    private func isFileTypeSupported(_ extension: String) -> Bool {
        let supportedTypes = [
            // Images
            "jpg", "jpeg", "png", "gif", "bmp", "tiff", "webp", "heic", "heif",
            // Documents
            "pdf", "doc", "docx", "txt", "rtf", "pages",
            // Spreadsheets
            "xls", "xlsx", "csv", "numbers",
            // Presentations
            "ppt", "pptx", "key",
            // Audio
            "mp3", "wav", "aac", "flac", "m4a", "ogg",
            // Video
            "mp4", "mov", "avi", "mkv", "wmv", "flv", "webm",
            // Archives
            "zip", "rar", "7z", "tar", "gz",
            // Other
            "json", "xml", "html", "css", "js"
        ]
        
        return supportedTypes.contains(extension)
    }
    
    // MARK: - File Type Detection
    
    private func getFileType(for extension: String) -> FileType {
        switch extension.lowercased() {
        case "jpg", "jpeg", "png", "gif", "bmp", "tiff", "webp", "heic", "heif":
            return .image
        case "pdf", "doc", "docx", "txt", "rtf", "pages":
            return .document
        case "xls", "xlsx", "csv", "numbers":
            return .spreadsheet
        case "ppt", "pptx", "key":
            return .presentation
        case "mp3", "wav", "aac", "flac", "m4a", "ogg":
            return .audio
        case "mp4", "mov", "avi", "mkv", "wmv", "flv", "webm":
            return .video
        case "zip", "rar", "7z", "tar", "gz":
            return .archive
        default:
            return .other
        }
    }
    
    private func getMimeType(for extension: String) -> String {
        if let utType = UTType(filenameExtension: extension) {
            return utType.preferredMIMEType ?? "application/octet-stream"
        }
        return "application/octet-stream"
    }
    
    // MARK: - Progress Tracking
    
    @MainActor
    private func updateUploadProgress(fileId: String, progress: Double) {
        uploadProgress[fileId] = progress
    }
    
    func getUploadProgress(for fileId: String) -> Double {
        return uploadProgress[fileId] ?? 0.0
    }
    
    // MARK: - Database Operations
    
    private func saveFileMetadata(_ file: UploadedFile) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw ContentManagementError.authenticationRequired
        }
        
        try await Firestore.firestore()
            .collection("users").document(userId)
            .collection("files")
            .document(file.id)
            .setData(from: file)
    }
    
    private func deleteFileMetadata(_ fileId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw ContentManagementError.authenticationRequired
        }
        
        try await Firestore.firestore()
            .collection("users").document(userId)
            .collection("files")
            .document(fileId)
            .delete()
    }
    
    // MARK: - Thumbnails
    
    /// Generates thumbnail for image files
    func generateThumbnail(for file: UploadedFile, size: CGSize = CGSize(width: 200, height: 200)) async -> UIImage? {
        guard file.type == .image,
              let url = URL(string: file.url) else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let image = UIImage(data: data) else { return nil }
            
            return await withCheckedContinuation { continuation in
                DispatchQueue.global(qos: .userInitiated).async {
                    let renderer = UIGraphicsImageRenderer(size: size)
                    let thumbnail = renderer.image { _ in
                        image.draw(in: CGRect(origin: .zero, size: size))
                    }
                    continuation.resume(returning: thumbnail)
                }
            }
        } catch {
            print("Error generating thumbnail: \(error)")
            return nil
        }
    }
    
    // MARK: - Storage Cleanup
    
    /// Cleans up orphaned files (files not associated with any SIF)
    func cleanupOrphanedFiles() async throws {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Get all files for user
        let filesSnapshot = try await Firestore.firestore()
            .collection("users").document(userId)
            .collection("files")
            .getDocuments()
        
        let files = filesSnapshot.documents.compactMap { doc in
            try? doc.data(as: UploadedFile.self)
        }
        
        // Get all SIFs for user
        let sifsSnapshot = try await Firestore.firestore()
            .collection("sifs")
            .whereField("authorUid", isEqualTo: userId)
            .getDocuments()
        
        let sifIds = Set(sifsSnapshot.documents.compactMap { $0.documentID })
        
        // Find orphaned files
        let orphanedFiles = files.filter { !sifIds.contains($0.sifId) }
        
        // Delete orphaned files
        for file in orphanedFiles {
            try await deleteFile(file)
        }
    }
}

// MARK: - Supporting Models

struct UploadedFile: Identifiable, Codable {
    let id: String
    let name: String
    let url: String
    let size: Int64
    let type: FileType
    let mimeType: String
    let uploadDate: Date
    let sifId: String
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

enum FileType: String, Codable, CaseIterable {
    case image = "image"
    case document = "document"
    case spreadsheet = "spreadsheet"
    case presentation = "presentation"
    case audio = "audio"
    case video = "video"
    case archive = "archive"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .image: return "Image"
        case .document: return "Document"
        case .spreadsheet: return "Spreadsheet"
        case .presentation: return "Presentation"
        case .audio: return "Audio"
        case .video: return "Video"
        case .archive: return "Archive"
        case .other: return "Other"
        }
    }
    
    var systemImageName: String {
        switch self {
        case .image: return "photo"
        case .document: return "doc.text"
        case .spreadsheet: return "tablecells"
        case .presentation: return "play.rectangle"
        case .audio: return "waveform"
        case .video: return "video"
        case .archive: return "archivebox"
        case .other: return "doc"
        }
    }
}

enum ContentManagementError: LocalizedError {
    case fileNotFound
    case fileTooLarge
    case unsupportedFileType
    case uploadFailed(String)
    case authenticationRequired
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "File not found"
        case .fileTooLarge:
            return "File is too large (max 100MB)"
        case .unsupportedFileType:
            return "Unsupported file type"
        case .uploadFailed(let reason):
            return "Upload failed: \(reason)"
        case .authenticationRequired:
            return "User authentication required"
        case .networkError:
            return "Network connection error"
        }
    }
}