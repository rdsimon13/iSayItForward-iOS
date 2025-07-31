import SwiftUI

struct PrimaryActionButtonStyle: ButtonStyle {
    let isEnabled: Bool
    let gradient: LinearGradient?
    
    init(isEnabled: Bool = true, gradient: LinearGradient? = nil) {
        self.isEnabled = isEnabled
        self.gradient = gradient
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                Group {
                    if let gradient = gradient {
                        gradient
                    } else {
                        Color.brandBlue
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(
                color: isEnabled ? Color.brandBlue.opacity(0.3) : Color.clear,
                radius: configuration.isPressed ? 2 : 4,
                y: configuration.isPressed ? 1 : 2
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.6)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
