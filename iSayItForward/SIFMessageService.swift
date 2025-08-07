import Foundation
import FirebaseAuth
import FirebaseFirestore
// import FirebaseStorage  // TODO: Add FirebaseStorage to project dependencies
import UIKit

// MARK: - Message Upload Status
enum MessageUploadStatus {
    case idle
    case uploading
    case completed
    case failed(Error)
}

// MARK: - Media Attachment
struct MediaAttachment: Codable, Identifiable {
    let id = UUID()
    let type: MediaType
    let localURL: URL?
    let remoteURL: String?
    let thumbnailURL: String?
    
    enum MediaType: String, Codable, CaseIterable {
        case photo = "photo"
        case video = "video"
    }
}

// MARK: - Message Draft
struct MessageDraft: Codable {
    let id: String
    var recipients: [String]
    var subject: String
    var message: String
    var categoryTags: [String]
    var privacyLevel: PrivacyLevel
    var mediaAttachments: [MediaAttachment]
    var scheduledDate: Date?
    let lastModified: Date
    
    enum PrivacyLevel: String, Codable, CaseIterable {
        case public = "public"
        case friends = "friends"
        case `private` = "private"
        
        var displayName: String {
            switch self {
            case .public: return "Public"
            case .friends: return "Friends Only"
            case .private: return "Private"
            }
        }
    }
}

// MARK: - SIF Message Service
class SIFMessageService: ObservableObject {
    @Published var uploadStatus: MessageUploadStatus = .idle
    @Published var uploadProgress: Double = 0.0
    
    private let db = Firestore.firestore()
    // private let storage = Storage.storage()  // TODO: Add FirebaseStorage to project dependencies
    private let userDefaults = UserDefaults.standard
    
    // MARK: - Draft Management
    func saveDraft(_ draft: MessageDraft) {
        do {
            let data = try JSONEncoder().encode(draft)
            userDefaults.set(data, forKey: "messageDraft_\(draft.id)")
        } catch {
            print("Failed to save draft: \(error)")
        }
    }
    
    func loadDraft(id: String) -> MessageDraft? {
        guard let data = userDefaults.data(forKey: "messageDraft_\(id)") else { return nil }
        do {
            return try JSONDecoder().decode(MessageDraft.self, from: data)
        } catch {
            print("Failed to load draft: \(error)")
            return nil
        }
    }
    
    func deleteDraft(id: String) {
        userDefaults.removeObject(forKey: "messageDraft_\(id)")
    }
    
    func getAllDrafts() -> [MessageDraft] {
        let keys = userDefaults.dictionaryRepresentation().keys.filter { $0.hasPrefix("messageDraft_") }
        return keys.compactMap { key in
            let id = String(key.dropFirst("messageDraft_".count))
            return loadDraft(id: id)
        }.sorted { $0.lastModified > $1.lastModified }
    }
    
    // MARK: - Media Upload (Placeholder - requires FirebaseStorage)
    func uploadMedia(_ data: Data, type: MediaAttachment.MediaType) async throws -> (remoteURL: String, thumbnailURL: String?) {
        // TODO: Implement when FirebaseStorage is added to project dependencies
        // For now, return placeholder URLs
        let placeholderURL = "https://placeholder.example.com/\(UUID().uuidString).\(type.rawValue)"
        return (remoteURL: placeholderURL, thumbnailURL: nil)
    }
    
    // MARK: - Message Upload
    func uploadMessage(from draft: MessageDraft) async throws -> String {
        guard let authorUid = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "SIFMessageService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        DispatchQueue.main.async {
            self.uploadStatus = .uploading
            self.uploadProgress = 0.0
        }
        
        // For now, skip media upload until FirebaseStorage is added
        var uploadedAttachments: [MediaAttachment] = []
        let totalSteps = 1 // Just message upload for now
        
        // Create SIFItem with attachments
        let sifItem = SIFItem(
            authorUid: authorUid,
            recipients: draft.recipients,
            subject: draft.subject,
            message: draft.message,
            createdDate: Date(),
            scheduledDate: draft.scheduledDate ?? Date(),
            attachmentURL: uploadedAttachments.first?.remoteURL,
            templateName: nil,
            categoryTags: draft.categoryTags,
            privacyLevel: draft.privacyLevel.rawValue,
            mediaAttachments: uploadedAttachments
        )
        
        // Upload to Firestore
        do {
            let documentRef = try db.collection("sifs").addDocument(from: sifItem)
            
            DispatchQueue.main.async {
                self.uploadProgress = 1.0
                self.uploadStatus = .completed
            }
            
            // Clean up draft after successful upload
            deleteDraft(id: draft.id)
            
            return documentRef.documentID
        } catch {
            DispatchQueue.main.async {
                self.uploadStatus = .failed(error)
            }
            throw error
        }
    }
    
    // MARK: - Delivery Scheduling
    func scheduleDelivery(for messageId: String, at date: Date) async throws {
        // In a real implementation, this would integrate with a scheduling service
        // For now, we'll update the Firestore document
        try await db.collection("sifs").document(messageId).updateData([
            "scheduledDate": date,
            "isScheduled": true
        ])
    }
    
    // MARK: - Error Recovery
    func retryFailedUpload(draft: MessageDraft) async throws -> String {
        return try await uploadMessage(from: draft)
    }
    
    // MARK: - Offline Support
    func cacheForOffline(_ draft: MessageDraft) {
        // Save draft locally for offline access
        saveDraft(draft)
        
        // Mark for upload when online
        var offlineQueue = userDefaults.stringArray(forKey: "offlineUploadQueue") ?? []
        if !offlineQueue.contains(draft.id) {
            offlineQueue.append(draft.id)
            userDefaults.set(offlineQueue, forKey: "offlineUploadQueue")
        }
    }
    
    func processOfflineQueue() async {
        let offlineQueue = userDefaults.stringArray(forKey: "offlineUploadQueue") ?? []
        var processedIds: [String] = []
        
        for draftId in offlineQueue {
            if let draft = loadDraft(id: draftId) {
                do {
                    _ = try await uploadMessage(from: draft)
                    processedIds.append(draftId)
                } catch {
                    print("Failed to upload offline draft \(draftId): \(error)")
                }
            }
        }
        
        // Remove processed items from queue
        let remainingQueue = offlineQueue.filter { !processedIds.contains($0) }
        userDefaults.set(remainingQueue, forKey: "offlineUploadQueue")
    }
}