import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

/// Service for managing message responses
class ResponseManager: ObservableObject {
    private let db = Firestore.firestore()
    private let signatureService = SignatureService()
    
    @Published var responses: [ResponseModel] = []
    @Published var isLoading = false
    @Published var error: ResponseError?
    @Published var validationStatus: ValidationStatus = .pending
    
    // MARK: - Response Creation
    func createResponse(
        to sifId: String,
        responseText: String,
        category: ResponseCategory,
        privacyLevel: PrivacyLevel = .public,
        requiresSignature: Bool = false,
        signatureImage: UIImage? = nil
    ) async throws -> ResponseModel {
        
        guard let currentUser = Auth.auth().currentUser else {
            throw ResponseError.authenticationRequired
        }
        
        // Validate response content
        try validateResponseContent(responseText)
        
        var signatureId: String? = nil
        
        // Handle signature if required
        if requiresSignature, let signatureImage = signatureImage {
            do {
                let signature = try await signatureService.createSignature(
                    from: signatureImage,
                    style: .handwritten,
                    documentContext: "Response to SIF: \(sifId)"
                )
                signatureId = signature.id
            } catch {
                throw ResponseError.signatureCreationFailed(error)
            }
        } else if requiresSignature {
            throw ResponseError.signatureRequired
        }
        
        let response = ResponseModel(
            authorUid: currentUser.uid,
            originalSIFId: sifId,
            responseText: responseText,
            category: category,
            privacyLevel: privacyLevel,
            requiresSignature: requiresSignature,
            signatureId: signatureId
        )
        
        try await saveResponse(response)
        
        await MainActor.run {
            self.responses.append(response)
        }
        
        return response
    }
    
    // MARK: - Response Validation
    private func validateResponseContent(_ text: String) throws {
        // Check minimum length
        guard text.trimmingCharacters(in: .whitespacesAndNewlines).count >= 10 else {
            throw ResponseError.responseTextTooShort
        }
        
        // Check maximum length
        guard text.count <= 5000 else {
            throw ResponseError.responseTextTooLong
        }
        
        // Basic content filtering (can be enhanced)
        let inappropriateWords = ["spam", "inappropriate"] // This would be a more comprehensive list
        let lowercaseText = text.lowercased()
        
        for word in inappropriateWords {
            if lowercaseText.contains(word) {
                throw ResponseError.inappropriateContent
            }
        }
    }
    
    // MARK: - Response Storage
    private func saveResponse(_ response: ResponseModel) async throws {
        do {
            let _ = try db.collection("responses").addDocument(from: response)
        } catch {
            throw ResponseError.saveFailed(error)
        }
    }
    
    // MARK: - Response Retrieval
    func loadResponsesForSIF(_ sifId: String) async {
        await MainActor.run {
            self.isLoading = true
            self.error = nil
        }
        
        do {
            let query = db.collection("responses")
                .whereField("originalSIFId", isEqualTo: sifId)
                .order(by: "createdDate", descending: true)
            
            let snapshot = try await query.getDocuments()
            let loadedResponses = try snapshot.documents.compactMap { document in
                try document.data(as: ResponseModel.self)
            }
            
            await MainActor.run {
                self.responses = loadedResponses
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = .loadFailed(error)
                self.isLoading = false
            }
        }
    }
    
    func loadUserResponses() async {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        await MainActor.run {
            self.isLoading = true
            self.error = nil
        }
        
        do {
            let query = db.collection("responses")
                .whereField("authorUid", isEqualTo: currentUser.uid)
                .order(by: "createdDate", descending: true)
            
            let snapshot = try await query.getDocuments()
            let loadedResponses = try snapshot.documents.compactMap { document in
                try document.data(as: ResponseModel.self)
            }
            
            await MainActor.run {
                self.responses = loadedResponses
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = .loadFailed(error)
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Response Privacy Management
    func updateResponsePrivacy(_ responseId: String, newPrivacyLevel: PrivacyLevel) async throws {
        do {
            try await db.collection("responses").document(responseId).updateData([
                "privacyLevel": newPrivacyLevel.rawValue
            ])
            
            // Update local model
            await MainActor.run {
                if let index = self.responses.firstIndex(where: { $0.id == responseId }) {
                    // Create updated response (since ResponseModel properties are let)
                    let oldResponse = self.responses[index]
                    // Note: In a real implementation, you'd need to make ResponseModel properties mutable
                    // or create a new instance with updated privacy level
                }
            }
        } catch {
            throw ResponseError.updateFailed(error)
        }
    }
    
    // MARK: - Response Categorization
    func suggestCategory(for responseText: String) -> ResponseCategory {
        let lowercaseText = responseText.lowercased()
        
        // Simple keyword-based categorization
        if lowercaseText.contains("thank") || lowercaseText.contains("grateful") || lowercaseText.contains("appreciate") {
            return .gratitude
        } else if lowercaseText.contains("?") || lowercaseText.contains("how") || lowercaseText.contains("what") || lowercaseText.contains("why") {
            return .question
        } else if lowercaseText.contains("suggest") || lowercaseText.contains("recommend") || lowercaseText.contains("idea") {
            return .suggestion
        } else if lowercaseText.contains("great") || lowercaseText.contains("amazing") || lowercaseText.contains("excellent") {
            return .compliment
        } else if lowercaseText.contains("feedback") || lowercaseText.contains("comment") {
            return .feedback
        } else if lowercaseText.contains("please") || lowercaseText.contains("could you") || lowercaseText.contains("need") {
            return .request
        } else if lowercaseText.contains("received") || lowercaseText.contains("understood") || lowercaseText.contains("noted") {
            return .acknowledgment
        }
        
        return .other
    }
    
    // MARK: - Impact Measurement
    func measureResponseImpact(_ response: ResponseModel) async -> Double {
        // Calculate impact score based on various factors
        var impactScore: Double = 0.0
        
        // Base score based on response length and quality
        let wordCount = response.responseText.components(separatedBy: .whitespacesAndNewlines).count
        impactScore += min(Double(wordCount) / 100.0, 1.0) * 0.3
        
        // Category-based scoring
        switch response.category {
        case .gratitude, .compliment:
            impactScore += 0.4
        case .feedback, .suggestion:
            impactScore += 0.3
        case .question, .request:
            impactScore += 0.2
        case .acknowledgment:
            impactScore += 0.1
        case .other:
            impactScore += 0.05
        }
        
        // Signature adds credibility
        if response.isSignatureValid {
            impactScore += 0.3
        }
        
        // Privacy level affects reach
        switch response.privacyLevel {
        case .public:
            impactScore += 0.0
        case .private:
            impactScore -= 0.1
        case .restricted:
            impactScore -= 0.05
        case .anonymous:
            impactScore -= 0.2
        }
        
        return min(max(impactScore, 0.0), 1.0) // Clamp between 0 and 1
    }
    
    // MARK: - Response Deletion
    func deleteResponse(_ response: ResponseModel) async throws {
        guard let responseId = response.id else {
            throw ResponseError.invalidResponseId
        }
        
        do {
            try await db.collection("responses").document(responseId).delete()
            
            await MainActor.run {
                self.responses.removeAll { $0.id == responseId }
            }
        } catch {
            throw ResponseError.deleteFailed(error)
        }
    }
}

// MARK: - Validation Status
enum ValidationStatus {
    case pending
    case validating
    case valid
    case invalid(reason: String)
}

// MARK: - Error Handling
enum ResponseError: LocalizedError {
    case authenticationRequired
    case responseTextTooShort
    case responseTextTooLong
    case inappropriateContent
    case signatureRequired
    case signatureCreationFailed(Error)
    case saveFailed(Error)
    case loadFailed(Error)
    case updateFailed(Error)
    case deleteFailed(Error)
    case invalidResponseId
    
    var errorDescription: String? {
        switch self {
        case .authenticationRequired:
            return "Authentication required to create response"
        case .responseTextTooShort:
            return "Response must be at least 10 characters long"
        case .responseTextTooLong:
            return "Response cannot exceed 5000 characters"
        case .inappropriateContent:
            return "Response contains inappropriate content"
        case .signatureRequired:
            return "Signature is required for this response"
        case .signatureCreationFailed(let error):
            return "Failed to create signature: \(error.localizedDescription)"
        case .saveFailed(let error):
            return "Failed to save response: \(error.localizedDescription)"
        case .loadFailed(let error):
            return "Failed to load responses: \(error.localizedDescription)"
        case .updateFailed(let error):
            return "Failed to update response: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete response: \(error.localizedDescription)"
        case .invalidResponseId:
            return "Invalid response ID"
        }
    }
}