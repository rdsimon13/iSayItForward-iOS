import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .padding()
            .frame(maxWidth: .infinity)
            .foregroundColor(Theme.textDark) // Dark text for the button label
            .background(Color.white)        // A clean, solid white background
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.2), radius: 5, y: 3)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}
