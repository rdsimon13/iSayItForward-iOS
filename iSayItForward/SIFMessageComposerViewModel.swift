import Foundation
import SwiftUI
import PhotosUI
import AVFoundation

// MARK: - Message Composer ViewModel
class SIFMessageComposerViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var recipients: String = ""
    @Published var subject: String = ""
    @Published var message: String = ""
    @Published var selectedTags: [String] = []
    @Published var privacyLevel: MessageDraft.PrivacyLevel = .public
    @Published var mediaAttachments: [MediaAttachment] = []
    @Published var shouldSchedule: Bool = false
    @Published var scheduledDate: Date = Date().addingTimeInterval(3600) // 1 hour from now
    
    // Validation and UI State
    @Published var isValidMessage: Bool = false
    @Published var validationErrors: [String] = []
    @Published var characterCount: Int = 0
    @Published var isDraft: Bool = false
    @Published var draftId: String = UUID().uuidString
    
    // Media handling
    @Published var showingImagePicker: Bool = false
    @Published var showingVideoPicker: Bool = false
    @Published var selectedPhotos: [PhotosPickerItem] = []
    
    // Constants
    let maxCharacterLimit: Int = 500
    let maxAttachments: Int = 5
    
    // Available tags/categories
    let availableTags = [
        "Encouragement", "Celebration", "Sympathy", "Announcement",
        "Holiday", "Birthday", "Achievement", "Support", "Love", "Friendship"
    ]
    
    // Dependencies
    private let messageService: SIFMessageService
    
    init(messageService: SIFMessageService = SIFMessageService()) {
        self.messageService = messageService
        setupObservers()
    }
    
    // MARK: - Setup
    private func setupObservers() {
        // Validate message whenever content changes
        $message
            .combineLatest($recipients, $subject)
            .map { [weak self] message, recipients, subject in
                self?.characterCount = message.count
                return self?.validateMessage(message: message, recipients: recipients, subject: subject) ?? false
            }
            .assign(to: &$isValidMessage)
        
        // Auto-save draft when content changes
        $message
            .combineLatest($recipients, $subject, $selectedTags, $privacyLevel)
            .debounce(for: .seconds(2), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.autoSaveDraft()
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Validation
    private func validateMessage(message: String, recipients: String, subject: String) -> Bool {
        validationErrors.removeAll()
        
        // Check required fields
        if recipients.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors.append("Recipients are required")
        }
        
        if subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors.append("Subject is required")
        }
        
        if message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors.append("Message content is required")
        }
        
        // Check character limit
        if message.count > maxCharacterLimit {
            validationErrors.append("Message exceeds \(maxCharacterLimit) character limit")
        }
        
        // Check attachment limit
        if mediaAttachments.count > maxAttachments {
            validationErrors.append("Too many attachments (max: \(maxAttachments))")
        }
        
        // Validate email format for recipients
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        let recipientList = recipients.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        
        for recipient in recipientList {
            if !recipient.isEmpty && !emailPredicate.evaluate(with: recipient) {
                validationErrors.append("Invalid email format: \(recipient)")
            }
        }
        
        return validationErrors.isEmpty
    }
    
    // MARK: - Draft Management
    func autoSaveDraft() {
        guard !message.isEmpty || !recipients.isEmpty || !subject.isEmpty else { return }
        
        let draft = createDraft()
        messageService.saveDraft(draft)
        isDraft = true
    }
    
    func saveDraft() {
        let draft = createDraft()
        messageService.saveDraft(draft)
        isDraft = true
    }
    
    func loadDraft(id: String) {
        guard let draft = messageService.loadDraft(id: id) else { return }
        
        self.draftId = draft.id
        self.recipients = draft.recipients.joined(separator: ", ")
        self.subject = draft.subject
        self.message = draft.message
        self.selectedTags = draft.categoryTags
        self.privacyLevel = draft.privacyLevel
        self.mediaAttachments = draft.mediaAttachments
        self.shouldSchedule = draft.scheduledDate != nil
        if let scheduledDate = draft.scheduledDate {
            self.scheduledDate = scheduledDate
        }
        self.isDraft = true
    }
    
    private func createDraft() -> MessageDraft {
        let recipientList = recipients.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        
        return MessageDraft(
            id: draftId,
            recipients: recipientList,
            subject: subject,
            message: message,
            categoryTags: selectedTags,
            privacyLevel: privacyLevel,
            mediaAttachments: mediaAttachments,
            scheduledDate: shouldSchedule ? scheduledDate : nil,
            lastModified: Date()
        )
    }
    
    // MARK: - Media Handling
    func addPhotoAttachment() {
        showingImagePicker = true
    }
    
    func addVideoAttachment() {
        showingVideoPicker = true
    }
    
    func handleSelectedPhotos() {
        Task {
            for item in selectedPhotos {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".jpg")
                    try? data.write(to: tempURL)
                    
                    let attachment = MediaAttachment(
                        type: .photo,
                        localURL: tempURL,
                        remoteURL: nil,
                        thumbnailURL: nil
                    )
                    
                    DispatchQueue.main.async {
                        self.mediaAttachments.append(attachment)
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.selectedPhotos.removeAll()
            }
        }
    }
    
    func removeAttachment(_ attachment: MediaAttachment) {
        mediaAttachments.removeAll { $0.id == attachment.id }
    }
    
    // MARK: - Tag Management
    func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.removeAll { $0 == tag }
        } else {
            selectedTags.append(tag)
        }
    }
    
    func isTagSelected(_ tag: String) -> Bool {
        selectedTags.contains(tag)
    }
    
    // MARK: - Message Operations
    func clearAll() {
        recipients = ""
        subject = ""
        message = ""
        selectedTags.removeAll()
        privacyLevel = .public
        mediaAttachments.removeAll()
        shouldSchedule = false
        scheduledDate = Date().addingTimeInterval(3600)
        isDraft = false
        draftId = UUID().uuidString
        
        // Clear any existing draft
        messageService.deleteDraft(id: draftId)
    }
    
    func sendMessage() async throws -> String {
        guard isValidMessage else {
            throw NSError(domain: "SIFMessageComposer", code: 400, userInfo: [NSLocalizedDescriptionKey: "Message validation failed"])
        }
        
        let draft = createDraft()
        let messageId = try await messageService.uploadMessage(from: draft)
        
        // Clear form after successful send
        DispatchQueue.main.async {
            self.clearAll()
        }
        
        return messageId
    }
    
    // MARK: - Preview Data
    func createPreviewSIF() -> SIFItem? {
        guard isValidMessage else { return nil }
        
        let recipientList = recipients.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        
        return SIFItem(
            authorUid: "preview",
            recipients: recipientList,
            subject: subject,
            message: message,
            createdDate: Date(),
            scheduledDate: shouldSchedule ? scheduledDate : Date(),
            attachmentURL: mediaAttachments.first?.remoteURL,
            templateName: nil,
            categoryTags: selectedTags,
            privacyLevel: privacyLevel.rawValue,
            mediaAttachments: mediaAttachments
        )
    }
}

// MARK: - Combine Import
import Combine