import Foundation
import UIKit
import FirebaseFirestore
import FirebaseAuth
import CoreLocation

/// Service for managing eSignature functionality
class SignatureService: ObservableObject {
    private let db = Firestore.firestore()
    private let locationManager = CLLocationManager()
    
    @Published var signatures: [SignatureModel] = []
    @Published var isLoading = false
    @Published var error: SignatureError?
    
    init() {
        setupLocationManager()
    }
    
    // MARK: - Setup
    private func setupLocationManager() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    // MARK: - Signature Creation
    func createSignature(from image: UIImage, style: SignatureStyle = .handwritten, documentContext: String? = nil) async throws -> SignatureModel {
        guard let currentUser = Auth.auth().currentUser else {
            throw SignatureError.authenticationRequired
        }
        
        guard let imageData = image.pngData() else {
            throw SignatureError.invalidImageData
        }
        
        let signature = SignatureModel(
            userUid: currentUser.uid,
            signatureData: imageData,
            documentContext: documentContext,
            signatureStyle: style,
            ipAddress: await getIPAddress(),
            deviceInfo: getDeviceInfo(),
            geoLocation: getCurrentLocation()
        )
        
        try await saveSignature(signature)
        
        await MainActor.run {
            self.signatures.append(signature)
        }
        
        return signature
    }
    
    // MARK: - Signature Storage
    private func saveSignature(_ signature: SignatureModel) async throws {
        do {
            let _ = try db.collection("signatures").addDocument(from: signature)
        } catch {
            throw SignatureError.saveFailed(error)
        }
    }
    
    // MARK: - Signature Retrieval
    func loadUserSignatures() async {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        await MainActor.run {
            self.isLoading = true
            self.error = nil
        }
        
        do {
            let query = db.collection("signatures")
                .whereField("userUid", isEqualTo: currentUser.uid)
                .order(by: "timestamp", descending: true)
            
            let snapshot = try await query.getDocuments()
            let loadedSignatures = try snapshot.documents.compactMap { document in
                try document.data(as: SignatureModel.self)
            }
            
            await MainActor.run {
                self.signatures = loadedSignatures
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = .loadFailed(error)
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Signature Validation
    func validateSignature(_ signatureId: String) async throws -> Bool {
        do {
            let document = try await db.collection("signatures").document(signatureId).getDocument()
            guard let signature = try? document.data(as: SignatureModel.self) else {
                throw SignatureError.signatureNotFound
            }
            
            // Validate signature integrity
            return validateSignatureIntegrity(signature)
        } catch {
            throw SignatureError.validationFailed(error)
        }
    }
    
    private func validateSignatureIntegrity(_ signature: SignatureModel) -> Bool {
        // Check if signature data is valid
        guard signature.image != nil else { return false }
        
        // Check timestamp validity (not future dated)
        guard signature.timestamp <= Date() else { return false }
        
        // Additional validation checks can be added here
        return true
    }
    
    // MARK: - Signature Deletion
    func deleteSignature(_ signature: SignatureModel) async throws {
        guard let signatureId = signature.id else {
            throw SignatureError.invalidSignatureId
        }
        
        do {
            try await db.collection("signatures").document(signatureId).delete()
            
            await MainActor.run {
                self.signatures.removeAll { $0.id == signatureId }
            }
        } catch {
            throw SignatureError.deleteFailed(error)
        }
    }
    
    // MARK: - Helper Methods
    private func getCurrentLocation() -> GeoLocation? {
        guard let location = locationManager.location else { return nil }
        
        return GeoLocation(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            accuracy: location.horizontalAccuracy
        )
    }
    
    private func getIPAddress() async -> String? {
        // In a real implementation, you would get the actual IP address
        // This is a placeholder implementation
        return "127.0.0.1"
    }
    
    private func getDeviceInfo() -> String {
        let device = UIDevice.current
        return "\(device.model) - \(device.systemName) \(device.systemVersion)"
    }
    
    // MARK: - Signature Preview
    func generateSignaturePreview(_ signature: SignatureModel) -> UIImage? {
        return signature.image
    }
    
    // MARK: - Multiple Signature Styles
    func createTypedSignature(text: String, font: UIFont = UIFont.systemFont(ofSize: 24)) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 300, height: 100))
        
        return renderer.image { context in
            let cgContext = context.cgContext
            cgContext.setFillColor(UIColor.black.cgColor)
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.black
            ]
            
            let attributedText = NSAttributedString(string: text, attributes: attributes)
            let textSize = attributedText.size()
            let textRect = CGRect(
                x: (300 - textSize.width) / 2,
                y: (100 - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            
            attributedText.draw(in: textRect)
        }
    }
}

// MARK: - Error Handling
enum SignatureError: LocalizedError {
    case authenticationRequired
    case invalidImageData
    case saveFailed(Error)
    case loadFailed(Error)
    case signatureNotFound
    case validationFailed(Error)
    case deleteFailed(Error)
    case invalidSignatureId
    
    var errorDescription: String? {
        switch self {
        case .authenticationRequired:
            return "Authentication required to save signature"
        case .invalidImageData:
            return "Unable to process signature image"
        case .saveFailed(let error):
            return "Failed to save signature: \(error.localizedDescription)"
        case .loadFailed(let error):
            return "Failed to load signatures: \(error.localizedDescription)"
        case .signatureNotFound:
            return "Signature not found"
        case .validationFailed(let error):
            return "Signature validation failed: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete signature: \(error.localizedDescription)"
        case .invalidSignatureId:
            return "Invalid signature ID"
        }
    }
}