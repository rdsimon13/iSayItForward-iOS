import SwiftUI
public struct PrimaryButton: View {
    public enum Style { case filled, outline }
    let title: String; let action: () -> Void; var style: Style
    public init(_ title: String, style: Style = .filled, action: @escaping () -> Void) {
        self.title = title; self.style = style; self.action = action
    }
    public var body: some View {
        Button(action: action) {
            Text(title).font(Theme.Typography.label()).frame(maxWidth: .infinity).padding(.vertical, Theme.Spacing.md)
        }
        .buttonStyle(.plain)
        .background(style == .filled ? Theme.ColorToken.accent : Color.clear)
        .foregroundColor(style == .filled ? .white : Theme.ColorToken.accent)
        .overlay(Capsule().stroke(Theme.ColorToken.accent, lineWidth: style == .outline ? 2 : 0))
        .clipShape(Capsule())
        .shadow(radius: style == .filled ? 3 : 0)
    }
}
