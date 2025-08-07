import Foundation
import FirebaseFirestore
import FirebaseStorage
import BackgroundTasks
import Combine

// MARK: - Send SIF Service
@MainActor
class SendSIFService: ObservableObject {
    // MARK: - Published Properties
    @Published var uploadProgress: [String: Double] = [:]
    @Published var sendingItems: Set<String> = []
    @Published var errorMessages: [String: String] = [:]
    
    // MARK: - Private Properties
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private var uploadTasks: [String: StorageUploadTask] = [:]
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    
    // MARK: - Constants
    private let maxRetryCount = 3
    private let chunkSize: Int64 = 1024 * 1024 // 1MB chunks
    private let largeFileThreshold: Int64 = 5 * 1024 * 1024 // 5MB
    
    // MARK: - Singleton
    static let shared = SendSIFService()
    
    private init() {
        setupBackgroundTaskRegistration()
    }
    
    // MARK: - Public Methods
    
    /// Send a SIF instantly
    func sendInstantly(_ sif: SIFItem) async throws {
        try await updateSIFStatus(sif, status: .sending)
        
        do {
            // Upload attachment if present
            var updatedSIF = sif
            if let attachmentURL = sif.attachmentURL {
                updatedSIF.attachmentURL = try await uploadAttachment(for: sif, localURL: URL(string: attachmentURL)!)
            }
            
            // Send the SIF
            try await performSend(updatedSIF)
            try await updateSIFStatus(updatedSIF, status: .sent)
            
        } catch {
            try await handleSendError(sif, error: error)
            throw error
        }
    }
    
    /// Schedule a SIF for later sending
    func scheduleForSending(_ sif: SIFItem, at date: Date) async throws {
        var updatedSIF = sif
        updatedSIF.scheduledDate = date
        updatedSIF.sendingStatus = .scheduled
        updatedSIF.isScheduled = true
        
        try await saveSIF(updatedSIF)
        
        // Schedule local notification if needed
        scheduleNotification(for: updatedSIF)
    }
    
    /// Retry a failed SIF
    func retrySending(_ sif: SIFItem) async throws {
        guard sif.canRetry else {
            throw SendSIFError.maxRetriesExceeded
        }
        
        var updatedSIF = sif
        updatedSIF.retryCount += 1
        updatedSIF.lastRetryDate = Date()
        updatedSIF.sendingStatus = .sending
        updatedSIF.errorMessage = nil
        
        try await sendInstantly(updatedSIF)
    }
    
    /// Cancel an ongoing upload
    func cancelUpload(for sifID: String) {
        uploadTasks[sifID]?.cancel()
        uploadTasks.removeValue(forKey: sifID)
        sendingItems.remove(sifID)
        uploadProgress.removeValue(forKey: sifID)
        
        Task {
            if let sif = try? await getSIF(id: sifID) {
                try? await updateSIFStatus(sif, status: .cancelled)
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Upload attachment with chunked upload for large files
    private func uploadAttachment(for sif: SIFItem, localURL: URL) async throws -> String {
        guard let sifID = sif.id else {
            throw SendSIFError.invalidSIFID
        }
        
        let fileSize = try getFileSize(url: localURL)
        let isLargeFile = fileSize > largeFileThreshold
        
        if isLargeFile {
            return try await uploadLargeFile(sifID: sifID, localURL: localURL, fileSize: fileSize)
        } else {
            return try await uploadSmallFile(sifID: sifID, localURL: localURL)
        }
    }
    
    /// Upload small file (< 5MB)
    private func uploadSmallFile(sifID: String, localURL: URL) async throws -> String {
        let storageRef = storage.reference().child("attachments/\(sifID)/\(localURL.lastPathComponent)")
        
        return try await withCheckedThrowingContinuation { continuation in
            let uploadTask = storageRef.putFile(from: localURL) { metadata, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    storageRef.downloadURL { url, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else if let url = url {
                            continuation.resume(returning: url.absoluteString)
                        }
                    }
                }
            }
            
            uploadTasks[sifID] = uploadTask
            
            uploadTask.observe(.progress) { [weak self] snapshot in
                guard let self = self, let progress = snapshot.progress else { return }
                let percentComplete = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
                
                Task { @MainActor in
                    self.uploadProgress[sifID] = percentComplete
                }
            }
        }
    }
    
    /// Upload large file (>= 5MB) with chunked upload
    private func uploadLargeFile(sifID: String, localURL: URL, fileSize: Int64) async throws -> String {
        startBackgroundTask()
        defer { endBackgroundTask() }
        
        let fileName = localURL.lastPathComponent
        let baseRef = storage.reference().child("attachments/\(sifID)/")
        
        let chunkCount = Int(ceil(Double(fileSize) / Double(chunkSize)))
        var chunkURLs: [String] = []
        
        let fileData = try Data(contentsOf: localURL)
        
        for chunkIndex in 0..<chunkCount {
            let startOffset = Int64(chunkIndex) * chunkSize
            let endOffset = min(startOffset + chunkSize, fileSize)
            let chunkData = fileData[Int(startOffset)..<Int(endOffset)]
            
            let chunkRef = baseRef.child("\(fileName).chunk.\(chunkIndex)")
            
            let chunkURL = try await withCheckedThrowingContinuation { continuation in
                let uploadTask = chunkRef.putData(chunkData) { metadata, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        chunkRef.downloadURL { url, error in
                            if let error = error {
                                continuation.resume(throwing: error)
                            } else if let url = url {
                                continuation.resume(returning: url.absoluteString)
                            }
                        }
                    }
                }
                
                uploadTask.observe(.progress) { [weak self] snapshot in
                    guard let self = self, let progress = snapshot.progress else { return }
                    let chunkProgress = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
                    let overallProgress = (Double(chunkIndex) + chunkProgress) / Double(chunkCount)
                    
                    Task { @MainActor in
                        self.uploadProgress[sifID] = overallProgress
                    }
                }
            }
            
            chunkURLs.append(chunkURL)
        }
        
        // Create metadata file with chunk information
        let metadata = ChunkedFileMetadata(
            fileName: fileName,
            totalSize: fileSize,
            chunkCount: chunkCount,
            chunkURLs: chunkURLs
        )
        
        let metadataData = try JSONEncoder().encode(metadata)
        let metadataRef = baseRef.child("\(fileName).metadata")
        
        return try await withCheckedThrowingContinuation { continuation in
            metadataRef.putData(metadataData) { _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    metadataRef.downloadURL { url, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else if let url = url {
                            continuation.resume(returning: url.absoluteString)
                        }
                    }
                }
            }
        }
    }
    
    /// Perform the actual sending of the SIF
    private func performSend(_ sif: SIFItem) async throws {
        // In a real implementation, this would call your backend API
        // For now, we'll simulate the sending process
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Update Firestore with the sent status
        try await saveSIF(sif)
    }
    
    /// Update SIF status in Firestore
    private func updateSIFStatus(_ sif: SIFItem, status: SIFSendingStatus) async throws {
        guard let sifID = sif.id else {
            throw SendSIFError.invalidSIFID
        }
        
        var updatedSIF = sif
        updatedSIF.sendingStatus = status
        
        try await saveSIF(updatedSIF)
    }
    
    /// Save SIF to Firestore
    private func saveSIF(_ sif: SIFItem) async throws {
        guard let sifID = sif.id else {
            throw SendSIFError.invalidSIFID
        }
        
        try await withCheckedThrowingContinuation { continuation in
            do {
                try db.collection("sifs").document(sifID).setData(from: sif) { error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// Get SIF from Firestore
    private func getSIF(id: String) async throws -> SIFItem {
        return try await withCheckedThrowingContinuation { continuation in
            db.collection("sifs").document(id).getDocument { snapshot, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let snapshot = snapshot, snapshot.exists {
                    do {
                        let sif = try snapshot.data(as: SIFItem.self)
                        continuation.resume(returning: sif)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                } else {
                    continuation.resume(throwing: SendSIFError.sifNotFound)
                }
            }
        }
    }
    
    /// Handle sending errors
    private func handleSendError(_ sif: SIFItem, error: Error) async throws {
        var updatedSIF = sif
        updatedSIF.sendingStatus = .failed
        updatedSIF.errorMessage = error.localizedDescription
        
        try await saveSIF(updatedSIF)
        
        await MainActor.run {
            errorMessages[sif.id ?? ""] = error.localizedDescription
        }
    }
    
    /// Get file size
    private func getFileSize(url: URL) throws -> Int64 {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        return attributes[.size] as? Int64 ?? 0
    }
    
    /// Schedule notification for scheduled SIFs
    private func scheduleNotification(for sif: SIFItem) {
        // Implementation for local notifications would go here
        // This is a placeholder for the notification scheduling logic
    }
    
    // MARK: - Background Task Management
    
    private func setupBackgroundTaskRegistration() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.isayitforward.upload", using: nil) { task in
            self.handleBackgroundUpload(task: task as! BGProcessingTask)
        }
    }
    
    private func startBackgroundTask() {
        backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "SIF Upload") {
            self.endBackgroundTask()
        }
    }
    
    private func endBackgroundTask() {
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
    }
    
    private func handleBackgroundUpload(task: BGProcessingTask) {
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        // Handle background upload logic here
        task.setTaskCompleted(success: true)
    }
}

// MARK: - Supporting Types

struct ChunkedFileMetadata: Codable {
    let fileName: String
    let totalSize: Int64
    let chunkCount: Int
    let chunkURLs: [String]
}

enum SendSIFError: LocalizedError {
    case invalidSIFID
    case maxRetriesExceeded
    case sifNotFound
    case uploadFailed
    case networkUnavailable
    
    var errorDescription: String? {
        switch self {
        case .invalidSIFID:
            return "Invalid SIF ID"
        case .maxRetriesExceeded:
            return "Maximum retry attempts exceeded"
        case .sifNotFound:
            return "SIF not found"
        case .uploadFailed:
            return "Upload failed"
        case .networkUnavailable:
            return "Network unavailable"
        }
    }
}