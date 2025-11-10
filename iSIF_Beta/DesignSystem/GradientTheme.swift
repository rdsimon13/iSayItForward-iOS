import SwiftUI

struct GradientTheme {
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
