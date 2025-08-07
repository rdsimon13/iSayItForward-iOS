import Foundation
import SwiftUI
import UIKit

// MARK: - Message Composer State Management
@MainActor
class SIFComposerViewModel: ObservableObject {
    // MARK: - Published Properties
    
    // Basic message fields
    @Published var recipients: [String] = []
    @Published var subject: String = ""
    @Published var message: String = ""
    
    // Recipient management
    @Published var recipientMode: RecipientMode = .single
    @Published var singleRecipient: String = ""
    @Published var multipleRecipients: String = ""
    @Published var selectedGroup: String = "Team"
    
    // Scheduling
    @Published var shouldSchedule: Bool = false
    @Published var scheduleDate: Date = Date()
    
    // Attachments
    @Published var attachments: [MessageAttachment] = []
    @Published var isSelectingAttachment: Bool = false
    
    // Privacy controls
    @Published var isPrivate: Bool = false
    @Published var allowForwarding: Bool = true
    @Published var requireReadReceipt: Bool = false
    
    // UI State
    @Published var isLoading: Bool = false
    @Published var showingAlert: Bool = false
    @Published var alertTitle: String = ""
    @Published var alertMessage: String = ""
    
    // MARK: - Dependencies
    private let messageService: MessageServiceProtocol
    
    // MARK: - Available groups (could be loaded from a service)
    let availableGroups = ["Team", "Family", "Friends", "Colleagues"]
    
    // MARK: - Initialization
    init(messageService: MessageServiceProtocol = SIFMessageService()) {
        self.messageService = messageService
    }
    
    // MARK: - Recipient Management
    
    func updateRecipients() {
        switch recipientMode {
        case .single:
            recipients = singleRecipient.isEmpty ? [] : [singleRecipient]
        case .multiple:
            recipients = multipleRecipients
                .split(separator: ",")
                .map { String($0.trimmingCharacters(in: .whitespaces)) }
                .filter { !$0.isEmpty }
        case .group:
            recipients = [selectedGroup]
        }
    }
    
    // MARK: - Attachment Management
    
    func addAttachment(_ attachment: MessageAttachment) {
        attachments.append(attachment)
    }
    
    func removeAttachment(at index: Int) {
        guard index < attachments.count else { return }
        attachments.remove(at: index)
    }
    
    func removeAttachment(_ attachment: MessageAttachment) {
        attachments.removeAll { $0.id == attachment.id }
    }
    
    // MARK: - Validation
    
    var canSendMessage: Bool {
        return !recipients.isEmpty && !message.isEmpty && !isLoading
    }
    
    func validateMessage() -> ValidationResult {
        updateRecipients()
        
        if recipients.isEmpty {
            return .failure("Please add at least one recipient")
        }
        
        if message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .failure("Please enter a message")
        }
        
        if subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .failure("Please enter a subject")
        }
        
        if shouldSchedule && scheduleDate <= Date() {
            return .failure("Scheduled date must be in the future")
        }
        
        return .success
    }
    
    // MARK: - Message Sending
    
    func sendMessage() async {
        let validation = validateMessage()
        
        switch validation {
        case .failure(let error):
            showAlert(title: "Validation Error", message: error)
            return
        case .success:
            break
        }
        
        isLoading = true
        
        do {
            // Upload attachments first
            var attachmentURLs: [String] = []
            
            for attachment in attachments {
                let url = try await messageService.uploadAttachment(attachment.data, fileName: attachment.fileName)
                attachmentURLs.append(url)
            }
            
            // Create the SIF message
            let sifMessage = SIFItem(
                id: nil,
                authorUid: "", // Will be set by service
                recipients: recipients,
                subject: subject,
                message: message,
                createdDate: Date(),
                scheduledDate: shouldSchedule ? scheduleDate : Date(),
                attachmentURL: attachmentURLs.first, // For backwards compatibility
                attachmentURLs: attachmentURLs.isEmpty ? nil : attachmentURLs,
                templateName: nil,
                isPrivate: isPrivate,
                allowForwarding: allowForwarding,
                requireReadReceipt: requireReadReceipt
            )
            
            // Send or schedule the message
            if shouldSchedule {
                try await messageService.scheduleMessage(sifMessage)
                showAlert(title: "Scheduled!", message: "Your SIF has been scheduled for delivery.")
            } else {
                try await messageService.sendMessage(sifMessage)
                showAlert(title: "Sent!", message: "Your SIF has been sent successfully.")
            }
            
            // Clear the form after successful send
            clearForm()
            
        } catch {
            showAlert(title: "Error", message: "Failed to send message: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    // MARK: - Form Management
    
    func clearForm() {
        recipients = []
        subject = ""
        message = ""
        singleRecipient = ""
        multipleRecipients = ""
        selectedGroup = availableGroups.first ?? "Team"
        shouldSchedule = false
        scheduleDate = Date()
        attachments = []
        isPrivate = false
        allowForwarding = true
        requireReadReceipt = false
    }
    
    // MARK: - Alert Management
    
    func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
}

// MARK: - Supporting Types

enum ValidationResult {
    case success
    case failure(String)
}

struct MessageAttachment: Identifiable, Equatable {
    let id = UUID()
    let data: Data
    let fileName: String
    let fileType: AttachmentType
    
    var displayName: String {
        return fileName
    }
    
    var fileSizeString: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(data.count))
    }
}

enum AttachmentType: String, CaseIterable {
    case image = "image"
    case document = "document"
    case other = "other"
    
    var systemImageName: String {
        switch self {
        case .image:
            return "photo"
        case .document:
            return "doc.text"
        case .other:
            return "paperclip"
        }
    }
}