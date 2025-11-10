import SwiftUI

/// A modern, theme-driven primary button used across the app.
/// Styles: `.filled` (blue/navy), `.outline` (white with blue border), `.accent` (gold)
struct PrimaryButton: View {

    // MARK: - Button Style
    enum Style: Equatable {
        case filled     // Navy blue (main CTA)
        case outline    // White w/ blue border
        case accent     // Gold/yellow (for schedule/send)
    }

    // MARK: - Properties
    let title: String
    var style: Style = .filled
    let action: () -> Void

    // MARK: - Initializer
    init(_ title: String, style: Style = .filled, action: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.action = action
    }

    // MARK: - Body
    var body: some View {
        Button(action: action) {
            Text(title.uppercased())
                .font(Theme.Font.label(16))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(backgroundColor)
                .foregroundColor(foregroundColor)
                .overlay(borderOverlay)
                .cornerRadius(Theme.Spacing.lg)
                .shadow(color: Theme.Colors.shadow, radius: 3, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Computed Style Values
    private var backgroundColor: Color {
        switch style {
        case .filled:
            return Theme.Colors.buttonPrimary     // 👈 your dark navy button color
        case .outline:
            return Color.white.opacity(0.95)
        case .accent:
            return Theme.Colors.accent            // gold/yellow
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .filled:
            return .white
        case .outline:
            return Theme.Colors.primary
        case .accent:
            return .white
        }
    }

    @ViewBuilder
    private var borderOverlay: some View {
        if style == .outline {
            RoundedRectangle(cornerRadius: Theme.Spacing.lg)
                .stroke(Theme.Colors.primary, lineWidth: 2)
        } else {
            RoundedRectangle(cornerRadius: Theme.Spacing.lg)
                .stroke(Color.clear, lineWidth: 0)
        }
    }
}
