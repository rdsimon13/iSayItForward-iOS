import SwiftUI

// This creates the custom style for our pill-shaped text fields.
struct PillTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(.white.opacity(0.8))
            .clipShape(Capsule()) // This creates the pill shape
            .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
            .onAppear {
                print("📝 PillTextFieldStyle loaded")
            }
    }
}
