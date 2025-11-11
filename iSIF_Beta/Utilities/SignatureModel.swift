import SwiftUI

// MARK: - Signature Drawing Model
struct DrawingPath {
    var points: [CGPoint] = []
    var lineWidth: CGFloat = 2.0
}

// MARK: - Signature Data Model
struct SignatureData: Identifiable, Codable {
    var id = UUID()
    let signatureImageData: Data
    let timestamp: Date
    let userUID: String

    init(signatureImageData: Data, userUID: String) {
        self.signatureImageData = signatureImageData
        self.timestamp = Date()
        self.userUID = userUID
    }
}
