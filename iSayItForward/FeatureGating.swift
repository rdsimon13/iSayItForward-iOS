import SwiftUI

// MARK: - Feature Gating Utilities
struct FeatureGate {
    private let subscriptionManager: SubscriptionManager
    
    init(subscriptionManager: SubscriptionManager) {
        self.subscriptionManager = subscriptionManager
    }
    
    // MARK: - Feature Access Checks
    func canUseESignature() -> Bool {
        guard let user = subscriptionManager.currentUser else { return false }
        return user.effectiveTier.allowsESignature
    }
    
    func shouldShowAds() -> Bool {
        guard let user = subscriptionManager.currentUser else { return true }
        return user.effectiveTier.showsAds
    }
    
    func canUploadFile(sizeInMB: Int) -> Bool {
        guard let user = subscriptionManager.currentUser else { return false }
        let limit = user.effectiveTier.dataLimitMB
        return limit == -1 || sizeInMB <= limit
    }
    
    func canCreateMoreSIFs() -> Bool {
        guard let user = subscriptionManager.currentUser else { return false }
        let limit = user.effectiveTier.maxSIFsPerMonth
        return limit == -1 // For now, just check unlimited
        // In a real app, you'd track usage and compare against limit
    }
    
    func hasFeatureAccess(requiredTier: UserTier) -> Bool {
        return subscriptionManager.canAccessFeature(requiredTier: requiredTier)
    }
}

// MARK: - Feature Gate View Modifier
struct FeatureGateModifier: ViewModifier {
    let requiredTier: UserTier
    let subscriptionManager: SubscriptionManager
    let showUpgradePrompt: Bool
    let upgradeAction: (() -> Void)?
    
    init(
        requiredTier: UserTier,
        subscriptionManager: SubscriptionManager,
        showUpgradePrompt: Bool = true,
        upgradeAction: (() -> Void)? = nil
    ) {
        self.requiredTier = requiredTier
        self.subscriptionManager = subscriptionManager
        self.showUpgradePrompt = showUpgradePrompt
        self.upgradeAction = upgradeAction
    }
    
    func body(content: Content) -> some View {
        Group {
            if subscriptionManager.canAccessFeature(requiredTier: requiredTier) {
                content
            } else if showUpgradePrompt {
                UpgradePromptView(
                    requiredTier: requiredTier,
                    upgradeAction: upgradeAction
                )
            } else {
                EmptyView()
            }
        }
    }
}

extension View {
    func featureGated(
        requiredTier: UserTier,
        subscriptionManager: SubscriptionManager,
        showUpgradePrompt: Bool = true,
        upgradeAction: (() -> Void)? = nil
    ) -> some View {
        modifier(FeatureGateModifier(
            requiredTier: requiredTier,
            subscriptionManager: subscriptionManager,
            showUpgradePrompt: showUpgradePrompt,
            upgradeAction: upgradeAction
        ))
    }
}

// MARK: - Upgrade Prompt View
struct UpgradePromptView: View {
    let requiredTier: UserTier
    let upgradeAction: (() -> Void)?
    
    var body: some View {
        ModernCard(backgroundColor: Color.neutralGray50) {
            VStack(spacing: 16) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 32))
                    .foregroundColor(Color.tierColor(for: requiredTier))
                
                VStack(spacing: 8) {
                    Text("Premium Feature")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.neutralGray800)
                    
                    Text("This feature requires \(requiredTier.displayName) plan")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.neutralGray600)
                        .multilineTextAlignment(.center)
                }
                
                if let upgradeAction = upgradeAction {
                    Button("Upgrade to \(requiredTier.displayName)") {
                        upgradeAction()
                    }
                    .buttonStyle(ModernPrimaryButtonStyle(
                        gradient: Color.tierGradient(for: requiredTier)
                    ))
                    .frame(maxWidth: 200)
                }
            }
            .padding(24)
        }
    }
}

// MARK: - Tier Requirement Badge
struct TierRequirementBadge: View {
    let requiredTier: UserTier
    let style: BadgeStyle
    
    enum BadgeStyle {
        case minimal
        case detailed
    }
    
    init(requiredTier: UserTier, style: BadgeStyle = .minimal) {
        self.requiredTier = requiredTier
        self.style = style
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "crown.fill")
                .font(.system(size: style == .minimal ? 8 : 10))
                .foregroundColor(Color.tierColor(for: requiredTier))
            
            if style == .detailed {
                Text("Requires \(requiredTier.displayName)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color.tierColor(for: requiredTier))
            }
        }
        .padding(.horizontal, style == .minimal ? 6 : 8)
        .padding(.vertical, style == .minimal ? 2 : 4)
        .background(Color.tierColor(for: requiredTier).opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: style == .minimal ? 6 : 8))
    }
}

// MARK: - Ad Banner Component
struct AdBannerView: View {
    let subscriptionManager: SubscriptionManager
    
    var body: some View {
        Group {
            if subscriptionManager.shouldShowAds() {
                ModernCard(backgroundColor: Color.neutralGray100) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Advertisement")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.neutralGray500)
                            
                            Text("Remove ads with Premium")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.neutralGray700)
                        }
                        
                        Spacer()
                        
                        Button("Upgrade") {
                            // Handle upgrade action
                        }
                        .buttonStyle(ModernTertiaryButtonStyle())
                        .font(.system(size: 12, weight: .semibold))
                    }
                    .padding(12)
                }
                .frame(height: 60)
            }
        }
    }
}

// MARK: - Usage Limit Warning
struct UsageLimitWarning: View {
    let currentUsage: Int
    let limit: Int
    let title: String
    let upgradeAction: (() -> Void)?
    
    private var percentage: Double {
        guard limit > 0 else { return 0 }
        return Double(currentUsage) / Double(limit)
    }
    
    private var warningLevel: WarningLevel {
        if percentage >= 0.9 { return .critical }
        if percentage >= 0.7 { return .warning }
        return .normal
    }
    
    enum WarningLevel {
        case normal, warning, critical
        
        var color: Color {
            switch self {
            case .normal: return .successGreen
            case .warning: return .warningYellow
            case .critical: return .errorRed
            }
        }
        
        var message: String {
            switch self {
            case .normal: return "You're within your limits"
            case .warning: return "Approaching your limit"
            case .critical: return "Limit almost reached"
            }
        }
    }
    
    var body: some View {
        Group {
            if limit > 0 && warningLevel != .normal {
                ModernCard(borderColor: warningLevel.color.opacity(0.3)) {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: warningLevel == .critical ? "exclamationmark.triangle.fill" : "info.circle.fill")
                                .foregroundColor(warningLevel.color)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(title)
                                    .font(.system(size: 14, weight: .semibold))
                                
                                Text("\(currentUsage) of \(limit) used")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.neutralGray600)
                            }
                            
                            Spacer()
                        }
                        
                        // Progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.neutralGray200)
                                    .frame(height: 4)
                                    .clipShape(RoundedRectangle(cornerRadius: 2))
                                
                                Rectangle()
                                    .fill(warningLevel.color)
                                    .frame(width: geometry.size.width * percentage, height: 4)
                                    .clipShape(RoundedRectangle(cornerRadius: 2))
                            }
                        }
                        .frame(height: 4)
                        
                        HStack {
                            Text(warningLevel.message)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.neutralGray600)
                            
                            Spacer()
                            
                            if let upgradeAction = upgradeAction {
                                Button("Upgrade") {
                                    upgradeAction()
                                }
                                .buttonStyle(ModernTertiaryButtonStyle())
                                .font(.system(size: 12, weight: .semibold))
                            }
                        }
                    }
                    .padding(16)
                }
            }
        }
    }
}