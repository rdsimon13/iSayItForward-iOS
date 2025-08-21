import SwiftUI
public struct Card<Content: View>: View {
    let content: Content
    public init(@ViewBuilder content: () -> Content) { self.content = content() }
    public var body: some View {
        content
            .padding(Theme.Spacing.lg)
            .background(Theme.ColorToken.cardFill)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.ColorToken.cardStroke, lineWidth: 1))
            .cornerRadius(14)
            .shadow(radius: 2, y: 1) // why: subtle elevation to match mock
    }
}
