import SwiftUI

struct Theme {

    // MARK: - Font Styles (Kodchasan-based)
    struct Font {
        static func heading(_ size: CGFloat = 28) -> SwiftUI.Font {
            .custom("Kodchasan-Bold", size: size)
        }

        static func subheading(_ size: CGFloat = 20) -> SwiftUI.Font {
            .custom("Kodchasan-SemiBold", size: size)
        }

        static func body(_ size: CGFloat = 16) -> SwiftUI.Font {
            .custom("Kodchasan-Regular", size: size)
        }

        static func label(_ size: CGFloat = 14) -> SwiftUI.Font {
            .custom("Kodchasan-Medium", size: size)
        }

        static func caption(_ size: CGFloat = 13) -> SwiftUI.Font {
            .custom("Kodchasan-Light", size: size)
        }
    }

    // MARK: - Brand Colors
    struct Colors {
        // ✅ Use your existing hex initializer (from project)
        static let primary = Color(hex: "#003366")         // Deep blue (logo text)
        static let secondary = Color(hex: "#00AEEF")       // Sky blue accent
        static let accent = Color(hex: "#F6C90E")          // Gold/yellow
        static let backgroundCard = Color.white.opacity(0.92)
        static let inputBackground = Color.white.opacity(0.95)
        static let textPrimary = Color(hex: "#1A1A1A")
        static let textSecondary = Color(hex: "#555555")
        static let shadow = Color.black.opacity(0.1)
        static let buttonPrimary = Color(hex: "#1A1A3F")   // Deep navy
        static let white = Color.white

        // Gradient background (for screens)
        static let backgroundGradient = LinearGradient(
            colors: [
                Color(red: 0.80, green: 0.95, blue: 1.0),  // top
                Color(red: 0.20, green: 0.80, blue: 1.0)   // bottom
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Gradients
    struct Gradients {
        static let goldPill = LinearGradient(
            colors: [Color(hex: "#FFD54F"), Color(hex: "#FFB300")],
            startPoint: .leading,
            endPoint: .trailing
        )

        static let blueFade = LinearGradient(
            colors: [Colors.secondary, Colors.primary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }

    // MARK: - Shadows
    struct Shadows {
        static let subtle = Shadow(color: Theme.Colors.shadow, radius: 3, y: 2)
        static let elevated = Shadow(color: Theme.Colors.shadow, radius: 6, y: 4)
    }

    struct Shadow {
        let color: Color
        let radius: CGFloat
        let y: CGFloat
    }

    // MARK: - Buttons
    struct Buttons {
        static func primary(text: String, action: @escaping () -> Void) -> some View {
            Button(action: action) {
                Text(text)
                    .font(Theme.Font.subheading(17))
                    .foregroundColor(.white)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(
                        Capsule()
                            .fill(Gradients.goldPill)
                            .shadow(color: .black.opacity(0.25), radius: 4, y: 3)
                    )
            }
            .buttonStyle(.plain)
        }

        static func secondary(text: String, action: @escaping () -> Void) -> some View {
            Button(action: action) {
                Text(text)
                    .font(Theme.Font.subheading(17))
                    .foregroundColor(Theme.Colors.primary)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(
                        Capsule()
                            .stroke(Theme.Colors.primary, lineWidth: 1.4)
                            .background(Capsule().fill(Color.white.opacity(0.85)))
                    )
            }
            .buttonStyle(.plain)
        }
    }
}
