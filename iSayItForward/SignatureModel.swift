import Foundation
import UIKit
import FirebaseFirestore

/// Model for storing signature data and metadata
struct SignatureModel: Identifiable, Codable, Hashable, Equatable {
    @DocumentID var id: String?
    
    let userUid: String
    let signatureData: Data // Base64 encoded image data
    let timestamp: Date
    let documentContext: String? // Context where signature was used
    let signatureStyle: SignatureStyle
    
    // Validation metadata
    let ipAddress: String?
    let deviceInfo: String?
    let geoLocation: GeoLocation?
    
    // Display properties
    var displayName: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return "Signature - \(formatter.string(from: timestamp))"
    }
    
    init(userUid: String, signatureData: Data, documentContext: String? = nil, signatureStyle: SignatureStyle = .handwritten, ipAddress: String? = nil, deviceInfo: String? = nil, geoLocation: GeoLocation? = nil) {
        self.userUid = userUid
        self.signatureData = signatureData
        self.timestamp = Date()
        self.documentContext = documentContext
        self.signatureStyle = signatureStyle
        self.ipAddress = ipAddress
        self.deviceInfo = deviceInfo
        self.geoLocation = geoLocation
    }
    
    // Convert signature data to UIImage
    var image: UIImage? {
        return UIImage(data: signatureData)
    }
    
    // Hashable & Equatable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: SignatureModel, rhs: SignatureModel) -> Bool {
        lhs.id == rhs.id
    }
}

/// Different signature styles supported
enum SignatureStyle: String, Codable, CaseIterable {
    case handwritten = "handwritten"
    case typed = "typed"
    case drawn = "drawn"
    
    var displayName: String {
        switch self {
        case .handwritten:
            return "Handwritten"
        case .typed:
            return "Typed"
        case .drawn:
            return "Drawn"
        }
    }
}

/// Geographic location data for signature validation
struct GeoLocation: Codable, Hashable {
    let latitude: Double
    let longitude: Double
    let accuracy: Double
    let timestamp: Date
    
    init(latitude: Double, longitude: Double, accuracy: Double) {
        self.latitude = latitude
        self.longitude = longitude
        self.accuracy = accuracy
        self.timestamp = Date()
    }
}