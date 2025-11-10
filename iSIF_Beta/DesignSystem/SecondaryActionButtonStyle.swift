import SwiftUI

struct SecondaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.heavy))
            .padding(.vertical, 15)
            .frame(maxWidth: .infinity)
            .foregroundColor(.white)
            .background(Color.brandDarkBlue) // Using our new theme color
            .clipShape(Capsule()) // Creates the pill shape
            .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0) // Adds a nice press effect
    }
}
