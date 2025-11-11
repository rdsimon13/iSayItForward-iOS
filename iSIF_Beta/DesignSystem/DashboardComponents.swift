import SwiftUI

// MARK: - Dashboard Utility Components

/// Reusable circular action button with icon and label.
/// (Used for quick actions elsewhere in the app, not in SIFDataManager)
struct DashboardCircleButton: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Button(action: action) {
                Image(systemName: icon)
                    .font(.system(size: 26))
                    .foregroundColor(.white)
                    .frame(width: 68, height: 68)
                    .background(
                        Circle()
                            .fill(Color.black.opacity(0.8))
                            .shadow(color: .black.opacity(0.25), radius: 5, y: 3)
                    )
            }

            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.black.opacity(0.8))
        }
    }
}

/// Simplified bottom navigation item (if you want to reuse outside SIFDataManager)
struct BottomNavItem: View {
    let icon: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(.black.opacity(0.8))
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.black.opacity(0.7))
        }
    }
}

/// Generic card container for wrapping content with a soft white background
// MARK: - Dashboard Card View
struct DashboardCardView<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(Color.white.opacity(0.96))
            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
            .overlay(content)
    }
}
