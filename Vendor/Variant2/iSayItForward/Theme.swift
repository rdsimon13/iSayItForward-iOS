import SwiftUI

enum Theme {
    // MARK: - Colors
    static let textDark = Color(hex: "#5D5D5D")
    static let textLightGray = Color(hex: "#8E8E93")
    static let darkTeal = Color(hex: "#008080")
    static let tabBrown = Color(hex: "#A52A2A") // A brown for the active tab state

    // MARK: - Gradients
    static let vibrantGradient = LinearGradient(
        gradient: Gradient(colors: [Color(hex: "#87CEEB"), Color(hex: "#00C4CC")]),
        startPoint: .top,
        endPoint: .bottom
    )
}
let background = Color(.systemGroupedBackground)

// Keep this Color extension in the same file
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted))
        var hexNumber: UInt64 = 0

        if scanner.scanHexInt64(&hexNumber) {
            let r = Double((hexNumber & 0xff0000) >> 16) / 255
            let g = Double((hexNumber & 0x00ff00) >> 8) / 255
            let b = Double(hexNumber & 0x0000ff) / 255
            self.init(red: r, green: g, blue: b)
        } else {
            self.init(.systemPink) // Fallback color
        }
    }
}
