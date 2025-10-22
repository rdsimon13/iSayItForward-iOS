import SwiftUI

struct Card<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding()
            .background(Theme.Colors.backgroundCard)
            .cornerRadius(20)
            .shadow(color: .gray.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}
