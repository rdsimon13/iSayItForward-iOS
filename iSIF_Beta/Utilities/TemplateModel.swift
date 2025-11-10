import SwiftUI

/// Lightweight model used only in-app (no Codable to avoid `Color` encoding issues)
struct TemplateModel: Identifiable, Equatable {
    var id: String
    var title: String
    var subtitle: String
    /// SF Symbol name (optional)
    var icon: String?
    /// Asset catalog image name (optional)
    var imageName: String?
    /// Background swatch for cards
    var color: Color
}

extension TemplateModel {
    /// Safe, in-app demo data
    static let sampleTemplates: [TemplateModel] = [
        .init(
            id: UUID().uuidString,
            title: "Sunset Bliss",
            subtitle: "Warm, gentle, reflective",
            icon: "sun.max.fill",
            imageName: nil,
            color: Color.orange.opacity(0.30)
        ),
        .init(
            id: UUID().uuidString,
            title: "Ocean Whisper",
            subtitle: "Calming, cool, peaceful",
            icon: "waveform",
            imageName: nil,
            color: Color.blue.opacity(0.30)
        ),
        .init(
            id: UUID().uuidString,
            title: "Minimal Calm",
            subtitle: "Simple, clean, modern",
            icon: "square.grid.2x2",
            imageName: nil,
            color: Color.gray.opacity(0.25)
        )
    ]
}
