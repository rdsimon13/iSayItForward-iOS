import SwiftUI

// MARK: - Enhanced Button Styles with Accessibility
struct EnhancedPrimaryActionButtonStyle: ButtonStyle {
    @State private var isPressed = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .padding(.vertical, 15)
            .frame(maxWidth: .infinity)
            .foregroundColor(.white)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.brandYellow)
                    .shadow(
                        color: Color.brandYellow.opacity(0.3),
                        radius: isPressed ? 2 : 8,
                        x: 0,
                        y: isPressed ? 1 : 4
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .onChange(of: configuration.isPressed) { pressed in
                isPressed = pressed
                if pressed {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                }
            }
            .accessibilityHint("Double tap to activate")
    }
}

struct EnhancedSecondaryActionButtonStyle: ButtonStyle {
    @State private var isPressed = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.heavy))
            .padding(.vertical, 15)
            .frame(maxWidth: .infinity)
            .foregroundColor(.white)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.brandDarkBlue)
                    .shadow(
                        color: Color.brandDarkBlue.opacity(0.3),
                        radius: isPressed ? 2 : 8,
                        x: 0,
                        y: isPressed ? 1 : 4
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .onChange(of: configuration.isPressed) { pressed in
                isPressed = pressed
                if pressed {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                }
            }
            .accessibilityHint("Double tap to activate")
    }
}

// MARK: - Enhanced Text Field Style
struct EnhancedPillTextFieldStyle: TextFieldStyle {
    let isError: Bool
    
    init(isError: Bool = false) {
        self.isError = isError
    }
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(
                Capsule()
                    .fill(.white.opacity(0.9))
                    .overlay(
                        Capsule()
                            .stroke(
                                isError ? Color.red : Color.clear,
                                lineWidth: isError ? 2 : 0
                            )
                    )
                    .shadow(
                        color: .black.opacity(0.1),
                        radius: 4,
                        x: 0,
                        y: 2
                    )
            )
            .accessibilityHint(isError ? "Input has validation error" : "Enter text here")
    }
}

// MARK: - Loading Button Modifier
struct LoadingButtonModifier: ViewModifier {
    let isLoading: Bool
    let loadingText: String
    let normalText: String
    
    func body(content: Content) -> some View {
        content
            .overlay(
                HStack(spacing: 8) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                    Text(isLoading ? loadingText : normalText)
                }
                .opacity(isLoading ? 1 : 0)
            )
    }
}

extension View {
    func loadingButton(isLoading: Bool, loadingText: String, normalText: String) -> some View {
        self.modifier(LoadingButtonModifier(isLoading: isLoading, loadingText: loadingText, normalText: normalText))
    }
}