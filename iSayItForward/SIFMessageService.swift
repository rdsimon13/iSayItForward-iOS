import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import UIKit

// MARK: - Message Service Protocol
protocol MessageServiceProtocol {
    func sendMessage(_ message: SIFItem) async throws
    func uploadAttachment(_ data: Data, fileName: String) async throws -> String
    func scheduleMessage(_ message: SIFItem) async throws
}

// MARK: - Firebase Message Service Implementation
@MainActor
class SIFMessageService: ObservableObject, MessageServiceProtocol {
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    // MARK: - Message Operations
    
    /// Sends a SIF message immediately
    func sendMessage(_ message: SIFItem) async throws {
        guard let authorUid = Auth.auth().currentUser?.uid else {
            throw MessageServiceError.notAuthenticated
        }
        
        var messageToSend = message
        messageToSend.authorUid = authorUid
        
        try await db.collection("sifs").addDocument(from: messageToSend)
    }
    
    /// Schedules a SIF message for future delivery
    func scheduleMessage(_ message: SIFItem) async throws {
        guard let authorUid = Auth.auth().currentUser?.uid else {
            throw MessageServiceError.notAuthenticated
        }
        
        var messageToSchedule = message
        messageToSchedule.authorUid = authorUid
        
        try await db.collection("scheduledSifs").addDocument(from: messageToSchedule)
    }
    
    // MARK: - Attachment Operations
    
    /// Uploads an attachment to Firebase Storage and returns the download URL
    func uploadAttachment(_ data: Data, fileName: String) async throws -> String {
        guard let authorUid = Auth.auth().currentUser?.uid else {
            throw MessageServiceError.notAuthenticated
        }
        
        let storageRef = storage.reference()
        let attachmentRef = storageRef.child("attachments/\(authorUid)/\(UUID().uuidString)_\(fileName)")
        
        let metadata = StorageMetadata()
        metadata.contentType = self.contentType(for: fileName)
        
        let _ = try await attachmentRef.putDataAsync(data, metadata: metadata)
        let downloadURL = try await attachmentRef.downloadURL()
        
        return downloadURL.absoluteString
    }
    
    // MARK: - Helper Methods
    
    private func contentType(for fileName: String) -> String {
        let fileExtension = (fileName as NSString).pathExtension.lowercased()
        
        switch fileExtension {
        case "jpg", "jpeg":
            return "image/jpeg"
        case "png":
            return "image/png"
        case "pdf":
            return "application/pdf"
        case "doc":
            return "application/msword"
        case "docx":
            return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        default:
            return "application/octet-stream"
        }
    }
}

// MARK: - Error Handling
enum MessageServiceError: LocalizedError {
    case notAuthenticated
    case uploadFailed
    case invalidData
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User is not authenticated"
        case .uploadFailed:
            return "Failed to upload attachment"
        case .invalidData:
            return "Invalid data provided"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}