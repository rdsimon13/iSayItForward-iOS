import SwiftUI

// MARK: - Drawing Stroke Model (for canvas operations)
struct DrawingStroke: Identifiable {
    let id = UUID()
    var points: [CGPoint] = []
    var lineWidth: CGFloat = 3.0
}

// MARK: - Signature Canvas
struct SignatureCanvas: View {
    @Binding var strokes: [DrawingStroke]
    @State private var currentStroke = DrawingStroke()

    var body: some View {
        Canvas { context, _ in
            // Completed strokes
            for stroke in strokes {
                var path = Path()
                if let first = stroke.points.first {
                    path.move(to: first)
                    for pt in stroke.points.dropFirst() { path.addLine(to: pt) }
                }
                context.stroke(path, with: .color(.black), lineWidth: stroke.lineWidth)
            }

            // Live stroke
            if let first = currentStroke.points.first {
                var live = Path()
                live.move(to: first)
                for pt in currentStroke.points.dropFirst() { live.addLine(to: pt) }
                context.stroke(live, with: .color(.black), lineWidth: currentStroke.lineWidth)
            }
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    currentStroke.points.append(value.location)
                }
                .onEnded { _ in
                    if !currentStroke.points.isEmpty {
                        strokes.append(currentStroke)
                        currentStroke = DrawingStroke()
                    }
                }
        )
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}
