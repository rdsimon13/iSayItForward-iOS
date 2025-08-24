import SwiftUI

// MARK: - Modern Color Palette
extension Color {
    // MARK: - Primary Brand Colors
    static let brandDarkBlue = Color(hex: "#1e293b")    // Darker, more sophisticated
    static let brandBlue = Color(hex: "#3b82f6")        // Modern blue
    static let brandLightBlue = Color(hex: "#60a5fa")   // Lighter accent
    static let brandYellow = Color(hex: "#fbbf24")      // Warmer yellow
    static let brandGold = Color(hex: "#f59e0b")        // Premium gold accent
    
    // MARK: - Neutral Colors
    static let neutralGray50 = Color(hex: "#f8fafc")
    static let neutralGray100 = Color(hex: "#f1f5f9")
    static let neutralGray200 = Color(hex: "#e2e8f0")
    static let neutralGray300 = Color(hex: "#cbd5e1")
    static let neutralGray400 = Color(hex: "#94a3b8")
    static let neutralGray500 = Color(hex: "#64748b")
    static let neutralGray600 = Color(hex: "#475569")
    static let neutralGray700 = Color(hex: "#334155")
    static let neutralGray800 = Color(hex: "#1e293b")
    static let neutralGray900 = Color(hex: "#0f172a")
    
    // MARK: - Semantic Colors
    static let successGreen = Color(hex: "#10b981")
    static let warningYellow = Color(hex: "#f59e0b")
    static let errorRed = Color(hex: "#ef4444")
    static let infoBlue = Color(hex: "#3b82f6")
    
    // MARK: - Tier Colors
    static let tierFree = Color(hex: "#64748b")         // Gray
    static let tierPremium = Color(hex: "#3b82f6")      // Blue
    static let tierPro = Color(hex: "#7c3aed")          // Purple
    
    // MARK: - Background Gradients
    static let mainAppGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color(hex: "#f8fafc"),
            Color(hex: "#e2e8f0")
        ]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let primaryGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color(hex: "#3b82f6"),
            Color(hex: "#1d4ed8")
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let premiumGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color(hex: "#fbbf24"),
            Color(hex: "#f59e0b")
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let proGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color(hex: "#8b5cf6"),
            Color(hex: "#7c3aed")
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let cardGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color.white,
            Color(hex: "#f8fafc")
        ]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    // MARK: - Dynamic Colors
    static func tierColor(for tier: UserTier) -> Color {
        switch tier {
        case .free: return tierFree
        case .premium: return tierPremium
        case .pro: return tierPro
        }
    }
    
    static func tierGradient(for tier: UserTier) -> LinearGradient {
        switch tier {
        case .free: return LinearGradient(
            gradient: Gradient(colors: [neutralGray400, neutralGray500]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        case .premium: return primaryGradient
        case .pro: return proGradient
        }
    }
}

// MARK: - Color Helpers
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
    }
    
    // Opacity variations
    func opacity(_ value: Double) -> Color {
        return self.opacity(value)
    }
    
    // Lighter/darker variations
    func lighter(by percentage: Double = 0.2) -> Color {
        return self.opacity(1.0 - percentage)
    }
    
    func darker(by percentage: Double = 0.2) -> Color {
        // This is a simplified version - in a real app you'd adjust HSB values
        return self.opacity(1.0 + percentage)
    }
}
