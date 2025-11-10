import SwiftUI

/// A reusable frosted-glass rounded card used across screens.
public struct FrostedRoundedCard<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        ZStack {
            // Frosted/blurred background
            RoundedRectangle(cornerRadius: 25)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.white.opacity(0.30))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Color.white.opacity(0.40), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.15), radius: 8, y: 3)

            VStack { content }
                .padding(8)
        }
    }
}
