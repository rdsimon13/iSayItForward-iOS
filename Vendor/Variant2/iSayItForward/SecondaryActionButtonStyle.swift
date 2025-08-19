import SwiftUI

struct SecondaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .padding()
            .frame(maxWidth: .infinity)
            .foregroundColor(.white) // White text
            .background(Color.clear) // Transparent background
            .overlay(
                // Add a white border to make it visible
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white, lineWidth: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

