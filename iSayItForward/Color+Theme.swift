import SwiftUI

// This is the new, correct code for the theme.
extension Color {
    // MARK: - Brand Colors
    static let brandDarkBlue = Color(hex: "#2e385c")
    static let brandYellow = Color(hex: "#ffac04")

    // MARK: - Gradient Colors
    private static let gradientStart = Color(hex: "#eefcff")
    private static let gradientEnd = Color(hex: "#89e9ff")
    
    // MARK: - Main App Gradient
    static let mainAppGradient = LinearGradient(
        gradient: Gradient(colors: [gradientStart, gradientEnd]),
        startPoint: .top,
        endPoint: .bottom
    )
}

// This helper function converts the hex codes to colors.
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex.trimmingCharacters(in: .whitespacesAndNewlines))
        if hex.hasPrefix("#") { _ = scanner.scanString("#") }
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
        
        // Debug logging for color creation
        #if DEBUG
        print("🎨 Color created from hex \(hex): RGB(\(r), \(g), \(b))")
        #endif
    }
}
