import SwiftUI

struct PrimaryPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                Capsule().fill(GradientTheme.primaryPill)
            )
            .shadow(color: .black.opacity(configuration.isPressed ? 0.15 : 0.35),
                    radius: configuration.isPressed ? 2 : 6, y: 4)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct GoldPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .bold, design: .rounded))
            .foregroundColor(BrandColor.textDark)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                Capsule().fill(GradientTheme.goldPill)
                    .overlay(Capsule().stroke(BrandColor.stroke, lineWidth: 1))
            )
            .shadow(color: .black.opacity(configuration.isPressed ? 0.15 : 0.3),
                    radius: 4, y: 3)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
