import SwiftUI

// MARK: - Social Login Button Component
struct SocialLoginButton: View {
    let imageName: String
    let systemFallback: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                // Background
                Circle()
                    .fill(Color.white.opacity(0.95))
                    .frame(width: 50, height: 50)
                    .shadow(color: .black.opacity(0.2), radius: 3, y: 2)

                // Icon image or SF Symbol fallback
                if let uiImage = UIImage(named: imageName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 26, height: 26)
                } else {
                    Image(systemName: systemFallback)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 26, height: 26)
                        .foregroundColor(.gray)
                }
            }
        }
        .buttonStyle(.plain)
        .padding(4)
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
