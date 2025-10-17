import SwiftUI

struct Theme {

    struct Font {
        static func heading(_ size: CGFloat) -> SwiftUI.Font {
            .system(size: size, weight: .bold, design: .rounded)
        }

        static func subheading(_ size: CGFloat) -> SwiftUI.Font {
            .system(size: size, weight: .semibold, design: .rounded)
        }

        static func body(_ size: CGFloat) -> SwiftUI.Font {
            .system(size: size, weight: .regular, design: .rounded)
        }

        static func label(_ size: CGFloat) -> SwiftUI.Font {
            .system(size: size, weight: .medium, design: .rounded)
        }
    }

    struct Colors {
        // Blue gradient background like in mockups
        static let backgroundGradient = LinearGradient(
            colors: [
                Color(red: 0.80, green: 0.95, blue: 1.0), // top (light cyan)
                Color(red: 0.20, green: 0.80, blue: 1.0)  // bottom (bright sky blue)
            ],
            startPoint: .top,
            endPoint: .bottom
        )

        // Core palette
        static let primary = Color(hex: "#003366")      // Deep blue (logo text)
        static let secondary = Color(hex: "#00AEEF")    // Sky blue accent
        static let accent = Color(hex: "#F6C90E")       // Yellow/Gold for “Schedule” button
        static let backgroundCard = Color.white.opacity(0.92)
        static let inputBackground = Color.white.opacity(0.95)
        static let textPrimary = Color(hex: "#1A1A1A")
        static let textSecondary = Color(hex: "#555555")
        static let shadow = Color.black.opacity(0.1)
        static let buttonPrimary = Color(hex: "#1A1A3F") // Deep navy
    }

    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }

    struct Shadows {
        static let subtle = Shadow(color: Theme.Colors.shadow, radius: 3, y: 2)
        static let elevated = Shadow(color: Theme.Colors.shadow, radius: 6, y: 4)
    }

    struct Shadow {
        let color: Color
        let radius: CGFloat
        let y: CGFloat
    }
}
