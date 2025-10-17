/* import SwiftUI

// MARK: - Safe color loader with hex + Asset fallback
extension Color {
    init(hex: String, opacity: Double = 1) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if s.hasPrefix("#") { s.removeFirst() }
        var rgb: UInt64 = 0
        Scanner(string: s).scanHexInt64(&rgb)

        let r, g, b: Double
        switch s.count {
        case 6:
            r = Double((rgb & 0xFF0000) >> 16) / 255.0
            g = Double((rgb & 0x00FF00) >> 8) / 255.0
            b = Double(rgb & 0x0000FF) / 255.0
        default:
            r = 1; g = 1; b = 1 // fallback white on bad input
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}

enum BrandColor {
    /// Blues from your mockups (adjust hex to exact Figma values if needed)
    static let blueTop     = Color(hex: "#7EC7FF")    // light top
    static let blueMid     = Color(hex: "#BFEAFA")    // soft mid
    static let blueBottom  = Color(hex: "#2D7BFF")    // deeper bottom

    /// Dark navy used on primary CTA + play bar
    static let navyStart   = Color(hex: "#0F132F")
    static let navyEnd     = Color(hex: "#070C26")

    /// Gold (Create Account + Schedule)
    static let gold        = Color(hex: "#F4E28E")    // muted gold
    static let goldDeep    = Color(hex: "#E0A100")    // shadow ring

    /// Neutrals
    static let textDark    = Color(hex: "#1C2A3A")
    static let textLight   = Color.white
    static let surface     = Color.white.opacity(0.95)
    static let stroke      = Color.black.opacity(0.25)
}
*/
