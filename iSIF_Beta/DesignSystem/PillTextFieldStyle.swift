import SwiftUI

struct PillTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                ZStack {
                    // Soft background fill
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.9),
                            Color(red: 0.8, green: 0.95, blue: 1.0).opacity(0.9)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    // Inner stroke effect
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Color.black.opacity(0.8), lineWidth: 0.6)
                }
            )
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.25), radius: 5, y: 3)
            .font(.custom("AvenirNext-Regular", size: 18))
            .foregroundColor(.black)
    }
}
