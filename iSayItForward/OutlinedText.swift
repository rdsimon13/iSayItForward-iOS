import SwiftUI

/// Draws text with an outline (stroke), fill, and shadow.
struct OutlinedText: View {
    var text: String
    var font: Font
    var fillColor: Color = .white
    var strokeColor: Color = .black
    var outlineWidth: CGFloat = 1.0
    var shadowColor: Color = .black.opacity(0.4)
    var shadowRadius: CGFloat = 4
    var tracking: CGFloat = 1.0

    var body: some View {
        ZStack {
            // 1️⃣ Draw stroke by layering multiple offset Texts
            ForEach(0..<8) { i in
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

            // 2️⃣ Fill text on top
            Text(text)
                .font(font)
                .tracking(tracking)
                .foregroundColor(fillColor)
                .shadow(color: shadowColor, radius: shadowRadius, y: 2)
        }
    }
}
