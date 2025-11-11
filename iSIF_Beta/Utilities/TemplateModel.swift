import SwiftUI

struct TemplateModel: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let subtitle: String
    var imageName: String?
    var icon: String?      // ✅ Added icon
    let colorHex: String

    var color: Color {
        Color(hex: colorHex)
    }

    init(id: String = UUID().uuidString, title: String, subtitle: String, imageName: String? = nil, icon: String? = nil, colorHex: String) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.imageName = imageName
        self.icon = icon
        self.colorHex = colorHex
    }

    // Convenience init for older code using Color directly (if needed, otherwise can be removed)
    init(id: String = UUID().uuidString, title: String, subtitle: String, imageName: String? = nil, icon: String? = nil, color: Color) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.imageName = imageName
        self.icon = icon
        // Fallback hex if we can't easily extract it from Color
        self.colorHex = "#000000"
    }

    // ✅ Added sampleTemplates
    static let sampleTemplates: [TemplateModel] = [
        TemplateModel(title: "Sunset Bliss", subtitle: "Warm, gentle, reflective", imageName: "sunset_placeholder", icon: "sun.max.fill", colorHex: "#FF9500"),
        TemplateModel(title: "Ocean Whisper", subtitle: "Calming, cool, peaceful", imageName: "ocean_placeholder", icon: "water.waves", colorHex: "#007AFF"),
        TemplateModel(title: "Minimal Calm", subtitle: "Simple, clean, modern", imageName: "calm_placeholder", icon: "leaf.fill", colorHex: "#8E8E93")
    ]
}
// NOTE: 'extension Color { init(hex: String) ... }' REMOVED here because it exists elsewhere in your project.
