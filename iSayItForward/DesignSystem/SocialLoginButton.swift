import SwiftUI

// MARK: - Social Login Button Component
struct SocialLoginButton: View {
    let imageName: String
    let systemFallback: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                // Background Circle
                Circle()
                    .fill(Color.white.opacity(0.95))
                    .frame(width: 50, height: 50)
                    .shadow(color: .black.opacity(0.15), radius: 3, y: 2)

                // Icon (Asset or SF Symbol fallback)
                Group {
                    if let uiImage = UIImage(named: imageName) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                    } else {
                        Image(systemName: systemFallback)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.gray)
                    }
                }
                .frame(width: 26, height: 26)
            }
            .contentShape(Circle()) // ensures full circular tap area
        }
        .buttonStyle(PressableButtonStyle()) // <— 👈 NEW: custom press animation style
        .padding(4)
    }
}

// MARK: - Press Animation Style
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 30) {
        SocialLoginButton(imageName: "googleLogo", systemFallback: "globe") {
            print("🌐 Google tapped")
        }
        SocialLoginButton(imageName: "microsoftLogo", systemFallback: "m.circle.fill") {
            print("🟣 Microsoft tapped")
        }
        SocialLoginButton(imageName: "appleLogo", systemFallback: "apple.logo") {
            print("🍎 Apple tapped")
        }
    }
    .padding()
    .background(Color.gray.opacity(0.2))
}
