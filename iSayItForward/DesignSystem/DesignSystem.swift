/*import SwiftUI

// MARK: - App Color Palette
enum AppColor {
    static let brandDarkBlue = Color(hex: "#0C1B40")
    static let brandYellow = Color(hex: "#FFD450")
    static let brandTeal = Color(hex: "#154D59")
    static let backgroundLight = Color(hex: "#E6F4F5")
    static let accentBrown = Color(hex: "#48211C")
    static let gradientTop = Color(hex: "#BEE5FF")
    static let gradientBottom = Color(hex: "#6DC4FA")
}

// MARK: - App Gradients
enum AppGradient {
    /// Used for the Sign Up / Sign In screens
    static let signUp = RadialGradient(
        gradient: Gradient(colors: [
            Color(hex: "#BEE5FF"),
            Color(hex: "#6DC4FA"),
            Color(hex: "#0C1B40").opacity(0.6)
        ]),
        center: .center,
        startRadius: 50,
        endRadius: 500
    )

    /// Used for main screens (Home, Create SIF, etc.)
    static let standard = LinearGradient(
        gradient: Gradient(colors: [
            Color(hex: "#BEE5FF"),
            Color(hex: "#6DC4FA")
        ]),
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Font System
enum AppFont {
    static func title(_ size: CGFloat) -> Font {
        .system(size: size, weight: .heavy, design: .rounded)
    }

    static func subtitle(_ size: CGFloat) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }

    static func body(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }

    static func button(_ size: CGFloat) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }
}

// MARK: - Shadow Tokens
enum AppShadow {
    static let soft = Color.black.opacity(0.1)
    static let medium = Color.black.opacity(0.15)
}

// MARK: - Hex Support
extension Color {
    init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
*/
