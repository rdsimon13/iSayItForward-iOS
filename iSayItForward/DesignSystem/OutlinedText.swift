import SwiftUI

/// A reusable outlined text view that supports fill, stroke, and shadow.
/// Works perfectly across multiple views (WelcomeView, SignupView, etc.)
struct OutlinedText: View {
    var text: String
    var font: Font = .system(size: 32, weight: .bold)
    var fillColor: Color = .white
    var strokeColor: Color = .black
    var outlineWidth: CGFloat = 1.5
    var shadowColor: Color = .black.opacity(0.3)
    var shadowRadius: CGFloat = 3
    var tracking: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Outline layer (8 directions)
            ForEach(0..<8, id: \.self) { i in
                let angle = Double(i) * .pi / 4
                Text(text)
                    .font(font)
                    .tracking(tracking)
                    .foregroundColor(strokeColor)
                    .offset(
                        x: CGFloat(cos(angle)) * outlineWidth,
                        y: CGFloat(sin(angle)) * outlineWidth
                    )
            }

            // Fill layer on top
            Text(text)
                .font(font)
                .tracking(tracking)
                .foregroundColor(fillColor)
                .shadow(color: shadowColor, radius: shadowRadius, y: 2)
        }
    }
}
