import SwiftUI

/// Defines all of the app's brand color constants in one place.
/// Used throughout the design system (buttons, backgrounds, gradients, etc.)
struct BrandColor {
    // MARK: - Blue Palette
    static let blueTop = Color(red: 0.05, green: 0.45, blue: 1.0)
    static let blueMid = Color(red: 0.25, green: 0.65, blue: 1.0)
    static let blueBottom = Color(red: 0.15, green: 0.55, blue: 0.95)

    // MARK: - Navy Palette
    static let navyStart = Color(red: 0.05, green: 0.10, blue: 0.25)
    static let navyEnd = Color(red: 0.02, green: 0.05, blue: 0.15)

    // MARK: - Gold Palette
    static let gold = Color(red: 1.0, green: 0.82, blue: 0.15)
    static let goldDeep = Color(red: 0.85, green: 0.65, blue: 0.05)

    // MARK: - Text & Surfaces
    static let textDark = Color(red: 0.10, green: 0.10, blue: 0.15)
    static let surface = Color.white
    static let stroke = Color.black.opacity(0.25)
}
