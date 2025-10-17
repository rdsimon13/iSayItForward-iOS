import SwiftUI

// MARK: - GradientTheme
struct GradientTheme {

    // MARK: - Welcome Background (Global Default)
    static var welcomeBackground: some View {
        LinearGradient(
            colors: [
                Color(hex: "#eefcff"),
                Color(hex: "#89e9ff")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static let goldPillColors: [Color] = [
        Color(red: 0.95, green: 0.75, blue: 0.20),
        Color(red: 0.10, green: 0.70, blue: 0.80)
    ]
    
    // MARK: - Primary Pill Gradient
    static var primaryPill: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: "#2e385c"),
                Color(hex: "#89e9ff")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    // MARK: - Deep Blue Gradient (for Dashboard Buttons)
    static var deepBlue: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: "#1a1f3c"),
                Color(hex: "#2e385c")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    // MARK: - Gold Pill Gradient
    static var goldPill: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: "#ffac04"),
                Color(hex: "#ffd65c")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Dashboard Background (Fixes Missing Member)
    static var dashboardBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "#2e385c"),
                    Color(hex: "#ffac04").opacity(0.35)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RadialGradient(
                colors: [
                    .white.opacity(0.15),
                    .clear
                ],
                center: .center,
                startRadius: 120,
                endRadius: 600
            )
            .blendMode(.screen)
        }
    }
}

extension Color {
    /// Initialize Color from HEX code
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17,
                            (int >> 4 & 0xF) * 17,
                            (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255,
                            int >> 16,
                            int >> 8 & 0xFF,
                            int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24,
                            int >> 16 & 0xFF,
                            int >> 8 & 0xFF,
                            int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
