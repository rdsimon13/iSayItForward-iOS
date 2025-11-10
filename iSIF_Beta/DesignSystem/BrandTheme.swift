import SwiftUI

// Global brand colors & gradients reused across screens

struct BrandTheme {
    // text colors
    static let titleStroke   = Color(hex: "132E37")
    static let titleFill     = Color(hex: "E6F4F5")
    static let pillBG        = Color(hex: "0F1C22") // deep navy/charcoal for pills
    static let cardText      = Color.black.opacity(0.85)
    static let cardSubtext   = Color.black.opacity(0.75)

    // background gradient (white -> soft ice blue -> 00CFFF at bottom)
    static let backgroundGradient = LinearGradient(
        gradient: Gradient(stops: [
            .init(color: .white, location: 0.0),
            .init(color: Color(red: 0.88, green: 0.96, blue: 1.0), location: 0.4),
            .init(color: Color(hex: "00CFFF"), location: 1.0)
        ]),
        startPoint: .top,
        endPoint: .bottom
    )
}
/*
// Safe hex init we already use elsewhere
extension Color {
    init(hex: String, opacity: Double = 1) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if s.hasPrefix("#") { s.removeFirst() }

        var rgb: UInt64 = 0
        Scanner(string: s).scanHexInt64(&rgb)

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0

        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}
*/
