import SwiftUI

// MARK: - Notification Badge View
struct NotificationBadgeView: View {
    @StateObject private var viewModel = NotificationBadgeViewModel()
    
    var body: some View {
        ZStack {
            if viewModel.showBadge {
                badgeContent
            }
        }
    }
    
    private var badgeContent: some View {
        Text(viewModel.badgeText)
            .font(viewModel.getBadgeFont())
            .foregroundColor(.white)
            .frame(width: viewModel.getBadgeSize().width, height: viewModel.getBadgeSize().height)
            .background(
                Circle()
                    .fill(viewModel.badgeColor)
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
            )
            .scaleEffect(viewModel.isAnimating ? 1.2 : 1.0)
            .opacity(viewModel.pulseAnimation ? 0.8 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.isAnimating)
            .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: viewModel.pulseAnimation)
            .accessibilityLabel(viewModel.accessibilityLabel)
            .accessibilityHint(viewModel.accessibilityHint)
    }
}

// MARK: - Tab Badge View (for use in tab bars)
struct TabBadgeView: View {
    let tab: AppTab
    @StateObject private var viewModel = NotificationBadgeViewModel()
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // This would contain your tab icon
            Image(systemName: tab.iconName)
                .font(.title2)
            
            if viewModel.getTabBadgeCount(for: tab) > 0 {
                Text("\(viewModel.getTabBadgeCount(for: tab))")
                    .font(.caption2.bold())
                    .foregroundColor(.white)
                    .frame(minWidth: 16, minHeight: 16)
                    .background(
                        Circle()
                            .fill(.red)
                    )
                    .offset(x: 8, y: -8)
            }
        }
    }
}

// MARK: - Custom Badge View with Configuration
struct CustomNotificationBadgeView: View {
    let count: Int
    let color: Color
    let size: BadgeSize
    let showZero: Bool
    
    init(count: Int, color: Color = .red, size: BadgeSize = .medium, showZero: Bool = false) {
        self.count = count
        self.color = color
        self.size = size
        self.showZero = showZero
    }
    
    var body: some View {
        if shouldShowBadge {
            Text(badgeText)
                .font(size.font)
                .foregroundColor(.white)
                .frame(width: size.width, height: size.height)
                .background(
                    Circle()
                        .fill(color)
                        .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                )
        }
    }
    
    private var shouldShowBadge: Bool {
        return count > 0 || (showZero && count == 0)
    }
    
    private var badgeText: String {
        if count <= 0 {
            return "0"
        } else if count > 99 {
            return "99+"
        } else {
            return "\(count)"
        }
    }
}

// MARK: - Badge Size Configuration
enum BadgeSize {
    case small
    case medium
    case large
    
    var width: CGFloat {
        switch self {
        case .small: return 16
        case .medium: return 20
        case .large: return 24
        }
    }
    
    var height: CGFloat {
        return width
    }
    
    var font: Font {
        switch self {
        case .small: return .caption2
        case .medium: return .caption2.bold()
        case .large: return .caption.bold()
        }
    }
}

// MARK: - Animated Badge View
struct AnimatedNotificationBadgeView: View {
    let count: Int
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0
    
    var body: some View {
        if count > 0 {
            Text(formatCount(count))
                .font(.caption2.bold())
                .foregroundColor(.white)
                .frame(minWidth: 20, minHeight: 20)
                .background(
                    Circle()
                        .fill(.red)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                )
                .scaleEffect(scale)
                .opacity(opacity)
                .onAppear {
                    animateAppearance()
                }
                .onChange(of: count) { newCount in
                    if newCount > count {
                        animateIncrease()
                    }
                }
        }
    }
    
    private func formatCount(_ count: Int) -> String {
        return count > 99 ? "99+" : "\(count)"
    }
    
    private func animateAppearance() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            scale = 1.0
            opacity = 1.0
        }
    }
    
    private func animateIncrease() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            scale = 1.2
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                scale = 1.0
            }
        }
    }
}

// MARK: - Badge Overlay Modifier
struct BadgeOverlay: ViewModifier {
    let count: Int
    let color: Color
    let offset: CGSize
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if count > 0 {
                        Text("\(count > 99 ? 99 : count)")
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                            .frame(minWidth: 18, minHeight: 18)
                            .background(
                                Circle()
                                    .fill(color)
                            )
                            .offset(offset)
                    }
                },
                alignment: .topTrailing
            )
    }
}

extension View {
    func badge(count: Int, color: Color = .red, offset: CGSize = CGSize(width: 8, height: -8)) -> some View {
        self.modifier(BadgeOverlay(count: count, color: color, offset: offset))
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        NotificationBadgeView()
        
        TabBadgeView(tab: .notifications)
        
        CustomNotificationBadgeView(count: 5)
        
        AnimatedNotificationBadgeView(count: 12)
        
        Image(systemName: "bell")
            .font(.title)
            .badge(count: 3)
    }
    .padding()
}