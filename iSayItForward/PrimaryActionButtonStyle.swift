import SwiftUI

struct PrimaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .padding(.vertical, 15)
            .frame(maxWidth: .infinity)
            .foregroundColor(.white)
            .background(Color.brandYellow) // Using our new yellow theme color
            .clipShape(Capsule()) // Creates the pill shape
            .shadow(color: Color.brandYellow.opacity(0.4), radius: 5, y: 3)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0) // Adds a nice press effect
            .onAppear {
                print("🟡 PrimaryActionButtonStyle loaded")
            }
    }
}
