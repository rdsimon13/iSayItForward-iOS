import SwiftUI

// This ViewModifier creates the frosted glass effect
struct FrostedGlassStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(.ultraThinMaterial) // This is the core of the glass effect
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
}

// This extension makes it easy to apply the style like this: .frostedGlass()
extension View {
    func frostedGlass() -> some View {
        self.modifier(FrostedGlassStyle())
    }
}
