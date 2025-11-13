import SwiftUI

// MARK: - Signature Data Model
public struct SignatureData: Identifiable, Codable {
    public var id = UUID()
    public let signatureImageData: Data
    public let timestamp: Date
    public let userUID: String
    
    public init(signatureImageData: Data, userUID: String) {
        self.signatureImageData = signatureImageData
        self.timestamp = Date()
        self.userUID = userUID
    }
}
