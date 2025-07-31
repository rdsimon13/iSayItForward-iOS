import SwiftUI

// MARK: - Modern Card Component
struct ModernCard<Content: View>: View {
    let content: Content
    let backgroundColor: Color
    let borderColor: Color?
    let shadowRadius: CGFloat
    let cornerRadius: CGFloat
    
    init(
        backgroundColor: Color = .white,
        borderColor: Color? = nil,
        shadowRadius: CGFloat = 4,
        cornerRadius: CGFloat = 16,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.shadowRadius = shadowRadius
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        content
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor ?? Color.clear, lineWidth: borderColor != nil ? 1 : 0)
            )
            .shadow(color: .black.opacity(0.1), radius: shadowRadius, y: 2)
    }
}

// MARK: - Modern Button Styles
struct ModernPrimaryButtonStyle: ButtonStyle {
    let isEnabled: Bool
    let gradient: LinearGradient?
    
    init(isEnabled: Bool = true, gradient: LinearGradient? = nil) {
        self.isEnabled = isEnabled
        self.gradient = gradient
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                Group {
                    if let gradient = gradient {
                        gradient
                    } else {
                        Color.brandBlue
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(
                color: isEnabled ? Color.brandBlue.opacity(0.3) : Color.clear,
                radius: configuration.isPressed ? 2 : 4,
                y: configuration.isPressed ? 1 : 2
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.6)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct ModernSecondaryButtonStyle: ButtonStyle {
    let isEnabled: Bool
    
    init(isEnabled: Bool = true) {
        self.isEnabled = isEnabled
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.brandBlue)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.brandBlue.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.brandBlue.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.6)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct ModernTertiaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.brandBlue)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Modern Text Field Style
struct ModernTextFieldStyle: TextFieldStyle {
    let iconName: String?
    let isSecure: Bool
    
    init(iconName: String? = nil, isSecure: Bool = false) {
        self.iconName = iconName
        self.isSecure = isSecure
    }
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        HStack(spacing: 12) {
            if let iconName = iconName {
                Image(systemName: iconName)
                    .foregroundColor(.neutralGray400)
                    .frame(width: 20)
            }
            
            configuration
                .font(.system(size: 16, weight: .medium))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.neutralGray50)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.neutralGray200, lineWidth: 1)
        )
    }
}

// MARK: - Floating Action Button
struct FloatingActionButton: View {
    let action: () -> Void
    let iconName: String
    let backgroundColor: Color
    let foregroundColor: Color
    
    init(
        iconName: String,
        backgroundColor: Color = .brandBlue,
        foregroundColor: Color = .white,
        action: @escaping () -> Void
    ) {
        self.iconName = iconName
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: iconName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(foregroundColor)
                .frame(width: 56, height: 56)
                .background(backgroundColor)
                .clipShape(Circle())
                .shadow(color: backgroundColor.opacity(0.3), radius: 8, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Modern Tab Bar Style
struct ModernTabBar<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .background(
                Rectangle()
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 4, y: -2)
            )
    }
}

// MARK: - Badge Component
struct Badge: View {
    let text: String
    let backgroundColor: Color
    let textColor: Color
    
    init(
        text: String,
        backgroundColor: Color = .brandBlue,
        textColor: Color = .white
    ) {
        self.text = text
        self.backgroundColor = backgroundColor
        self.textColor = textColor
    }
    
    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(textColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Loading State Component
struct LoadingView: View {
    let message: String
    
    init(message: String = "Loading...") {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(.brandBlue)
            
            Text(message)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.neutralGray600)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.neutralGray50.opacity(0.8))
    }
}

// MARK: - Empty State Component
struct EmptyStateView: View {
    let iconName: String
    let title: String
    let description: String
    let actionText: String?
    let action: (() -> Void)?
    
    init(
        iconName: String,
        title: String,
        description: String,
        actionText: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.iconName = iconName
        self.title = title
        self.description = description
        self.actionText = actionText
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: iconName)
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.neutralGray400)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.neutralGray700)
                
                Text(description)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.neutralGray500)
                    .multilineTextAlignment(.center)
            }
            
            if let actionText = actionText, let action = action {
                Button(actionText, action: action)
                    .buttonStyle(ModernPrimaryButtonStyle())
                    .frame(maxWidth: 200)
            }
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Tier Badge Component
struct TierBadge: View {
    let tier: UserTier
    let style: TierBadgeStyle
    
    enum TierBadgeStyle {
        case compact
        case detailed
    }
    
    init(tier: UserTier, style: TierBadgeStyle = .compact) {
        self.tier = tier
        self.style = style
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color.tierColor(for: tier))
                .frame(width: 8, height: 8)
            
            Text(tier.displayName.uppercased())
                .font(.system(size: style == .compact ? 10 : 12, weight: .bold))
                .foregroundColor(Color.tierColor(for: tier))
            
            if style == .detailed {
                Text("PLAN")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.neutralGray500)
            }
        }
        .padding(.horizontal, style == .compact ? 8 : 12)
        .padding(.vertical, style == .compact ? 4 : 6)
        .background(Color.tierColor(for: tier).opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: style == .compact ? 8 : 12))
    }
}