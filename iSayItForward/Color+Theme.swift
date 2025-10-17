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
    static let main = LinearGradient(
        gradient: Gradient(colors: [gradientStart, gradientEnd]),
        startPoint: .top,
        endPoint: .bottom
    )
}

