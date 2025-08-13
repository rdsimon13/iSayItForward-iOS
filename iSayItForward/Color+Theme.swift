// iSayItForward/Color+Theme.swift
import SwiftUI

extension Color {
    // MARK: - Brand Colors (kept from your project; adjust as needed)
    static let brandDarkBlue = Color(hex: "#2e385c")
    static let brandYellow   = Color(hex: "#ffac04")

    // MARK: - Gradient Colors (UPDATED to match ProfileView’s look)
    // Old: #eefcff → #89e9ff (very light)
    // New: brighter, modern blue/cyan sweep
    private static let gradientTop    = Color(hex: "#1FA2FF") // sky blue
    private static let gradientMiddle = Color(hex: "#12D8FA") // cyan
    private static let gradientBottom = Color(hex: "#1FA2FF") // subtle loop

    // MARK: - App-wide gradient (source of truth)
    static let mainAppGradient = LinearGradient(
        gradient: Gradient(colors: [gradientTop, gradientMiddle, gradientBottom]),
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Hex init convenience (kept)
extension Color {
    init(hex: String) {
        let s = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var n: UInt64 = 0; Scanner(string: s).scanHexInt64(&n)
        let r, g, b, a: UInt64
        switch s.count {
        case 3: (r,g,b,a) = ((n>>8)*17, (n>>4 & 0xF)*17, (n & 0xF)*17, 255)
        case 6: (r,g,b,a) = (n>>16, n>>8 & 0xFF, n & 0xFF, 255)
        case 8: (r,g,b,a) = (n>>24, n>>16 & 0xFF, n>>8 & 0xFF, n & 0xFF)
        default: (r,g,b,a) = (0,0,0,255)
        }
        self.init(.sRGB,
                  red:   Double(r)/255,
                  green: Double(g)/255,
                  blue:  Double(b)/255,
                  opacity: Double(a)/255)
    }
}
// Add at the bottom of Color+Theme.swift (after the hex initializer)
extension Color {
    /// Slightly different blue used on Profile to give that intentional identity
    static let profileGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color(hex: "#1DA1F2"), // a touch darker than main
            Color(hex: "#12D8FA"),
            Color(hex: "#1FA2FF")
        ]),
        startPoint: .top,
        endPoint: .bottom
    )
}
