import SwiftUI

/// A reusable gradient capsule-shaped button that fits your iSayItForward design system.
struct GradientCapsuleButton: View {
    enum Style {
        case primary   // deep blue gradient
        case gold      // yellow gradient (signup)
        case neutral   // white subtle gradient
    }

    var title: String? = nil
    var systemImage: String? = nil
    var style: Style = .primary
    var isLoading: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: {
            if !isLoading {
                action()
            }
        }) {
            ZStack {
                Capsule()
                    .fill(gradientForStyle)
                    .frame(height: 56)
                    .overlay(
                        Capsule().stroke(Color.black.opacity(0.25), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.25), radius: 4, y: 3)

                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else if let title = title {
                    HStack(spacing: 8) {
                        if let systemImage = systemImage {
                            Image(systemName: systemImage)
                                .font(.system(size: 18, weight: .semibold))
                        }
                        Text(title)
                            .font(TextStyles.subtitle(17))
                            .tracking(1)
                    }
                    .foregroundColor(foregroundForStyle)
                } else if let systemImage = systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(foregroundForStyle)
                }
            }
            .padding(.horizontal, 50)
            .animation(.easeInOut(duration: 0.2), value: isLoading)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }

    // MARK: - Private Helpers
    private var gradientForStyle: LinearGradient {
        switch style {
        case .primary:
            return LinearGradient(
                colors: [
                    Color(red: 0.07, green: 0.08, blue: 0.25),
                    Color(red: 0.02, green: 0.05, blue: 0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .gold:
            return LinearGradient(
                colors: [
                    Color(hex: "#ffac04"),
                    Color(hex: "#ffcf48")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .neutral:
            return LinearGradient(
                colors: [
                    Color.white.opacity(0.9),
                    Color.white.opacity(0.7)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var foregroundForStyle: Color {
        switch style {
        case .primary:
            return .white
        case .gold:
            return Color(red: 0.2, green: 0.15, blue: 0.05)
        case .neutral:
            return Color.black.opacity(0.8)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        GradientCapsuleButton(title: "Primary Button", style: .primary) {}
        GradientCapsuleButton(title: "Gold Button", style: .gold) {}
        GradientCapsuleButton(title: "Neutral Button", style: .neutral) {}
        GradientCapsuleButton(systemImage: "paperplane.fill", style: .primary) {}
    }
    .padding()
    .background(Color.gray.opacity(0.2))
}
