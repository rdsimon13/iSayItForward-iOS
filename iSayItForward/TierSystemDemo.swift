import SwiftUI

// MARK: - Demo Tier System
struct TierSystemDemo: View {
    @StateObject private var subscriptionManager = SubscriptionManager()
    @State private var currentDemoTier: UserTier = .free
    @State private var showingTierSelection = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Text("Tier System Demo")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.neutralGray800)
                        
                        Text("Experience the three-tier subscription system")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.neutralGray600)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)
                    
                    // Current tier display
                    ModernCard {
                        VStack(spacing: 16) {
                            HStack {
                                Text("Current Plan")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.neutralGray800)
                                
                                Spacer()
                                
                                TierBadge(tier: currentDemoTier, style: .detailed)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Features:")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.neutralGray700)
                                
                                ForEach(currentDemoTier.features, id: \.self) { feature in
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(.successGreen)
                                        
                                        Text(feature)
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.neutralGray600)
                                        
                                        Spacer()
                                    }
                                }
                            }
                            
                            Button("Change Plan") {
                                showingTierSelection = true
                            }
                            .buttonStyle(ModernSecondaryButtonStyle())
                        }
                        .padding(20)
                    }
                    
                    // Feature demonstrations based on current tier
                    VStack(spacing: 16) {
                        // E-signature feature
                        FeatureDemo(
                            title: "E-Signature Support",
                            description: "Add legally binding signatures to your SIFs",
                            iconName: "signature",
                            requiredTier: .premium,
                            currentTier: currentDemoTier,
                            upgradeAction: { showingTierSelection = true }
                        )
                        
                        // Data storage
                        FeatureDemo(
                            title: "Data Storage",
                            description: "Upload larger files and media",
                            iconName: "icloud.and.arrow.up",
                            requiredTier: .premium,
                            currentTier: currentDemoTier,
                            upgradeAction: { showingTierSelection = true },
                            customContent: {
                                DataStorageIndicator(tier: currentDemoTier)
                            }
                        )
                        
                        // Ads removal
                        if currentDemoTier.showsAds {
                            AdBannerDemo()
                        } else {
                            FeatureDemo(
                                title: "Ad-Free Experience",
                                description: "Enjoy iSayItForward without advertisements",
                                iconName: "rectangle.slash",
                                requiredTier: .premium,
                                currentTier: currentDemoTier,
                                upgradeAction: { showingTierSelection = true }
                            )
                        }
                        
                        // Pro features
                        FeatureDemo(
                            title: "Analytics Dashboard",
                            description: "Track engagement and delivery metrics",
                            iconName: "chart.bar.fill",
                            requiredTier: .pro,
                            currentTier: currentDemoTier,
                            upgradeAction: { showingTierSelection = true }
                        )
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
            }
            .background(Color.mainAppGradient)
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingTierSelection) {
            TierSelectionDemoView(
                currentTier: $currentDemoTier,
                onDismiss: { showingTierSelection = false }
            )
        }
    }
}

// MARK: - Feature Demo Component
struct FeatureDemo<Content: View>: View {
    let title: String
    let description: String
    let iconName: String
    let requiredTier: UserTier
    let currentTier: UserTier
    let upgradeAction: () -> Void
    let customContent: (() -> Content)?
    
    init(
        title: String,
        description: String,
        iconName: String,
        requiredTier: UserTier,
        currentTier: UserTier,
        upgradeAction: @escaping () -> Void,
        @ViewBuilder customContent: @escaping () -> Content = { EmptyView() }
    ) {
        self.title = title
        self.description = description
        self.iconName = iconName
        self.requiredTier = requiredTier
        self.currentTier = currentTier
        self.upgradeAction = upgradeAction
        self.customContent = customContent
    }
    
    var hasAccess: Bool {
        currentTier.canAccessFeature(requiredTier: requiredTier)
    }
    
    var body: some View {
        ModernCard(borderColor: hasAccess ? Color.successGreen.opacity(0.3) : nil) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: iconName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(hasAccess ? .successGreen : Color.tierColor(for: requiredTier))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.neutralGray800)
                        
                        Text(description)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.neutralGray600)
                    }
                    
                    Spacer()
                    
                    if hasAccess {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.successGreen)
                    } else {
                        TierRequirementBadge(requiredTier: requiredTier)
                    }
                }
                
                if let customContent = customContent {
                    customContent()
                }
                
                if !hasAccess {
                    Button("Upgrade to \(requiredTier.displayName)") {
                        upgradeAction()
                    }
                    .buttonStyle(ModernPrimaryButtonStyle(
                        gradient: Color.tierGradient(for: requiredTier)
                    ))
                    .frame(height: 40)
                }
            }
            .padding(20)
            .opacity(hasAccess ? 1.0 : 0.8)
        }
    }
}

// MARK: - Data Storage Indicator
struct DataStorageIndicator: View {
    let tier: UserTier
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Storage Limit:")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.neutralGray600)
                
                Spacer()
                
                Text(tier.dataLimitMB == -1 ? "Unlimited" : "\(tier.dataLimitMB) MB")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.brandBlue)
            }
            
            if tier.dataLimitMB != -1 {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.neutralGray200)
                            .frame(height: 4)
                            .clipShape(RoundedRectangle(cornerRadius: 2))
                        
                        Rectangle()
                            .fill(Color.brandBlue)
                            .frame(width: geometry.size.width * 0.6, height: 4) // 60% used for demo
                            .clipShape(RoundedRectangle(cornerRadius: 2))
                    }
                }
                .frame(height: 4)
                
                Text("60% used (demo)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.neutralGray500)
            }
        }
    }
}

// MARK: - Ad Banner Demo
struct AdBannerDemo: View {
    var body: some View {
        ModernCard(backgroundColor: Color.neutralGray100) {
            VStack(spacing: 12) {
                HStack {
                    Text("Advertisement")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.neutralGray500)
                    
                    Spacer()
                    
                    Text("AD")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.neutralGray400)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                
                Text("Remove ads with Premium or Pro plans")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.neutralGray700)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
        }
    }
}

// MARK: - Demo Tier Selection
struct TierSelectionDemoView: View {
    @Binding var currentTier: UserTier
    let onDismiss: () -> Void
    
    @State private var selectedTier: UserTier = .free
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Choose Your Plan")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .padding(.top)
                
                LazyVStack(spacing: 16) {
                    ForEach(UserTier.allCases, id: \.rawValue) { tier in
                        TierCard(
                            tier: tier,
                            isSelected: selectedTier == tier,
                            isCurrentTier: currentTier == tier,
                            onSelect: { selectedTier = tier }
                        )
                    }
                }
                
                Button("Select \(selectedTier.displayName)") {
                    currentTier = selectedTier
                    onDismiss()
                }
                .buttonStyle(ModernPrimaryButtonStyle(
                    gradient: Color.tierGradient(for: selectedTier)
                ))
                
                Button("Cancel") {
                    onDismiss()
                }
                .buttonStyle(ModernTertiaryButtonStyle())
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .background(Color.mainAppGradient)
            .navigationBarHidden(true)
        }
        .onAppear {
            selectedTier = currentTier
        }
    }
}

struct TierSystemDemo_Previews: PreviewProvider {
    static var previews: some View {
        TierSystemDemo()
    }
}