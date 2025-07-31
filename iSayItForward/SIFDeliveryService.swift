import Foundation
import FirebaseFirestore
import FirebaseAuth
import BackgroundTasks
import UserNotifications

// Service responsible for SIF delivery, retry mechanisms, and status tracking
class SIFDeliveryService: ObservableObject {
    static let shared = SIFDeliveryService()
    
    @Published var deliveryProgress: [String: Double] = [:]
    @Published var activeDeliveries: Set<String> = []
    
    private let db = Firestore.firestore()
    private let maxRetryAttempts = 3
    private let retryDelaySeconds: TimeInterval = 30
    
    private init() {
        setupBackgroundTaskHandling()
    }
    
    // MARK: - Delivery Management
    
    /// Initiates immediate delivery of a SIF
    func deliverSIF(_ sif: SIFItem) async throws {
        guard let sifId = sif.id else {
            throw SIFDeliveryError.invalidSIF
        }
        
        await updateSIFStatus(sifId: sifId, status: .processing)
        activeDeliveries.insert(sifId)
        
        do {
            // Handle large file uploads first if any attachments exist
            if !sif.attachmentURLs.isEmpty {
                await updateSIFStatus(sifId: sifId, status: .uploading)
                try await uploadAttachments(for: sif)
            }
            
            // Process the actual delivery
            try await processDelivery(for: sif)
            
            // Mark as delivered
            await updateSIFStatus(sifId: sifId, status: .delivered)
            await updateDeliveredDate(sifId: sifId, date: Date())
            
            // Send delivery notification if enabled
            if sif.notifyOnDelivery {
                await sendDeliveryNotification(for: sif)
            }
            
        } catch {
            await handleDeliveryFailure(sif: sif, error: error)
        }
        
        activeDeliveries.remove(sifId)
        deliveryProgress.removeValue(forKey: sifId)
    }
    
    /// Schedules a SIF for future delivery
    func scheduleSIF(_ sif: SIFItem) async throws {
        guard let sifId = sif.id else {
            throw SIFDeliveryError.invalidSIF
        }
        
        await updateSIFStatus(sifId: sifId, status: .scheduled)
        
        // Schedule background task for delivery
        await scheduleBackgroundDelivery(for: sif)
    }
    
    /// Cancels a scheduled SIF
    func cancelSIF(sifId: String) async throws {
        await updateSIFStatus(sifId: sifId, status: .cancelled)
        await updateCancelledDate(sifId: sifId, date: Date())
        
        // Cancel any pending background tasks
        await cancelBackgroundDelivery(sifId: sifId)
    }
    
    /// Extends the expiration date of a SIF
    func extendSIFExpiration(sifId: String, newExpirationDate: Date) async throws {
        try await db.collection("sifs").document(sifId).updateData([
            "expirationDate": newExpirationDate
        ])
    }
    
    // MARK: - Progress Tracking
    
    func updateProgress(for sifId: String, progress: Double) {
        DispatchQueue.main.async {
            self.deliveryProgress[sifId] = progress
        }
    }
    
    func getProgress(for sifId: String) -> Double {
        return deliveryProgress[sifId] ?? 0.0
    }
    
    // MARK: - Private Implementation
    
    private func processDelivery(for sif: SIFItem) async throws {
        guard let sifId = sif.id else {
            throw SIFDeliveryError.invalidSIF
        }
        
        // Simulate delivery process with progress updates
        for i in 1...10 {
            updateProgress(for: sifId, progress: Double(i) / 10.0)
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
        }
        
        // Generate QR code and shareable link
        let qrCodeData = generateQRCodeData(for: sif)
        let shareableLink = generateShareableLink(for: sif)
        
        try await db.collection("sifs").document(sifId).updateData([
            "qrCodeData": qrCodeData,
            "shareableLink": shareableLink,
            "progressPercentage": 100.0
        ])
    }
    
    private func uploadAttachments(for sif: SIFItem) async throws {
        guard let sifId = sif.id else {
            throw SIFDeliveryError.invalidSIF
        }
        
        let totalSize = sif.totalAttachmentSize
        var uploadedSize: Int64 = 0
        
        // Simulate attachment upload with progress
        for (index, url) in sif.attachmentURLs.enumerated() {
            let fileSize = index < sif.attachmentSizes.count ? sif.attachmentSizes[index] : 0
            
            // Simulate chunk upload
            let chunks = max(1, Int(fileSize / 1024 / 1024)) // 1MB chunks
            for chunk in 1...chunks {
                uploadedSize += min(1024 * 1024, fileSize - Int64((chunk - 1) * 1024 * 1024))
                let progress = Double(uploadedSize) / Double(totalSize) * 0.8 // 80% for upload, 20% for processing
                updateProgress(for: sifId, progress: progress)
                try await Task.sleep(nanoseconds: 50_000_000) // 0.05 second delay
            }
        }
    }
    
    private func handleDeliveryFailure(sif: SIFItem, error: Error) async {
        guard let sifId = sif.id else { return }
        
        let newRetryCount = sif.retryCount + 1
        
        if newRetryCount <= maxRetryAttempts {
            // Schedule retry
            await updateRetryInfo(sifId: sifId, retryCount: newRetryCount, lastRetryDate: Date())
            
            DispatchQueue.global().asyncAfter(deadline: .now() + retryDelaySeconds) {
                Task {
                    try? await self.retryDelivery(sifId: sifId)
                }
            }
        } else {
            // Mark as failed
            await updateSIFStatus(sifId: sifId, status: .failed)
            await updateFailureReason(sifId: sifId, reason: error.localizedDescription)
        }
    }
    
    private func retryDelivery(sifId: String) async throws {
        // Fetch the latest SIF data and retry delivery
        let document = try await db.collection("sifs").document(sifId).getDocument()
        if let sif = try? document.data(as: SIFItem.self) {
            try await deliverSIF(sif)
        }
    }
    
    // MARK: - Database Updates
    
    private func updateSIFStatus(sifId: String, status: SIFDeliveryStatus) async {
        try? await db.collection("sifs").document(sifId).updateData([
            "deliveryStatus": status.rawValue
        ])
    }
    
    private func updateDeliveredDate(sifId: String, date: Date) async {
        try? await db.collection("sifs").document(sifId).updateData([
            "deliveredDate": date
        ])
    }
    
    private func updateCancelledDate(sifId: String, date: Date) async {
        try? await db.collection("sifs").document(sifId).updateData([
            "cancelledDate": date,
            "isCancelled": true
        ])
    }
    
    private func updateRetryInfo(sifId: String, retryCount: Int, lastRetryDate: Date) async {
        try? await db.collection("sifs").document(sifId).updateData([
            "retryCount": retryCount,
            "lastRetryDate": lastRetryDate
        ])
    }
    
    private func updateFailureReason(sifId: String, reason: String) async {
        try? await db.collection("sifs").document(sifId).updateData([
            "failureReason": reason
        ])
    }
    
    // MARK: - QR Code and Link Generation
    
    private func generateQRCodeData(for sif: SIFItem) -> String {
        // Generate unique QR code data
        let baseURL = "https://isayitforward.app/sif/"
        return "\(baseURL)\(sif.id ?? UUID().uuidString)"
    }
    
    private func generateShareableLink(for sif: SIFItem) -> String {
        // Generate shareable deep link
        let baseURL = "https://isayitforward.app/share/"
        return "\(baseURL)\(sif.id ?? UUID().uuidString)"
    }
    
    // MARK: - Background Tasks
    
    private func setupBackgroundTaskHandling() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.isayitforward.delivery", using: nil) { task in
            self.handleBackgroundDelivery(task: task as! BGAppRefreshTask)
        }
    }
    
    private func scheduleBackgroundDelivery(for sif: SIFItem) async {
        let request = BGAppRefreshTaskRequest(identifier: "com.isayitforward.delivery")
        request.earliestBeginDate = sif.scheduledDate
        
        try? BGTaskScheduler.shared.submit(request)
    }
    
    private func cancelBackgroundDelivery(sifId: String) async {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: "com.isayitforward.delivery")
    }
    
    private func handleBackgroundDelivery(task: BGAppRefreshTask) {
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        Task {
            // Fetch and process scheduled SIFs
            await processScheduledSIFs()
            task.setTaskCompleted(success: true)
        }
    }
    
    private func processScheduledSIFs() async {
        do {
            let snapshot = try await db.collection("sifs")
                .whereField("deliveryStatus", isEqualTo: SIFDeliveryStatus.scheduled.rawValue)
                .whereField("scheduledDate", isLessThanOrEqualTo: Date())
                .getDocuments()
            
            for document in snapshot.documents {
                if let sif = try? document.data(as: SIFItem.self) {
                    try? await deliverSIF(sif)
                }
            }
        } catch {
            print("Error processing scheduled SIFs: \(error)")
        }
    }
    
    // MARK: - Notifications
    
    private func sendDeliveryNotification(for sif: SIFItem) async {
        let content = UNMutableNotificationContent()
        content.title = "SIF Delivered"
        content.body = "Your SIF '\(sif.subject)' has been delivered successfully."
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "delivery-\(sif.id ?? UUID().uuidString)",
            content: content,
            trigger: nil
        )
        
        try? await UNUserNotificationCenter.current().add(request)
        
        // Update notification status
        if let sifId = sif.id {
            try? await db.collection("sifs").document(sifId).updateData([
                "deliveryNotificationSent": true
            ])
        }
    }
}

// MARK: - Error Types

enum SIFDeliveryError: LocalizedError {
    case invalidSIF
    case uploadFailed
    case deliveryFailed
    case networkError
    case authenticationRequired
    
    var errorDescription: String? {
        switch self {
        case .invalidSIF:
            return "Invalid SIF data"
        case .uploadFailed:
            return "Failed to upload attachments"
        case .deliveryFailed:
            return "Failed to deliver SIF"
        case .networkError:
            return "Network connection error"
        case .authenticationRequired:
            return "User authentication required"
        }
    }
}