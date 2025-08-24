import SwiftUI

// MARK: - UI Component Preview
struct UIComponentShowcase: View {
    @State private var selectedTier: UserTier = .free
    @State private var showingTierSelection = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    Text("iSayItForward UI Showcase")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.neutralGray800)
                        .padding(.top)
                    
                    // Tier badges
                    VStack(spacing: 12) {
                        Text("Tier Badges")
                            .font(.system(size: 18, weight: .semibold))
                        
                        HStack(spacing: 16) {
                            TierBadge(tier: .free)
                            TierBadge(tier: .premium)
                            TierBadge(tier: .pro)
                        }
                        
                        HStack(spacing: 16) {
                            TierBadge(tier: .free, style: .detailed)
                            TierBadge(tier: .premium, style: .detailed)
                            TierBadge(tier: .pro, style: .detailed)
                        }
                    }
                    
                    // Modern cards
                    ModernCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Modern Card Example")
                                .font(.system(size: 18, weight: .semibold))
                            
                            Text("This is a modern card component with clean styling, subtle shadows, and rounded corners that creates a polished look.")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.neutralGray600)
                            
                            HStack {
                                Button("Primary") { }
                                    .buttonStyle(ModernPrimaryButtonStyle())
                                    .frame(height: 40)
                                
                                Button("Secondary") { }
                                    .buttonStyle(ModernSecondaryButtonStyle())
                                    .frame(height: 40)
                            }
                        }
                        .padding(20)
                    }
                    
                    // Feature gating example
                    ModernCard {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("E-Signature Feature")
                                    .font(.system(size: 18, weight: .semibold))
                                
                                TierRequirementBadge(requiredTier: .premium, style: .detailed)
                                
                                Spacer()
                            }
                            
                            if selectedTier.canAccessFeature(requiredTier: .premium) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("✓ E-signature support enabled")
                                        .foregroundColor(.successGreen)
                                        .font(.system(size: 14, weight: .medium))
                                    
                                    Text("You can now add legally binding e-signatures to your SIFs.")
                                        .font(.system(size: 14))
                                        .foregroundColor(.neutralGray600)
                                }
                            } else {
                                UpgradePromptView(
                                    requiredTier: .premium,
                                    upgradeAction: {
                                        showingTierSelection = true
                                    }
                                )
                            }
                        }
                        .padding(20)
                    }
                    
                    // Tier selector
                    VStack(spacing: 12) {
                        Text("Current Tier Selection")
                            .font(.system(size: 18, weight: .semibold))
                        
                        Picker("Tier", selection: $selectedTier) {
                            ForEach(UserTier.allCases, id: \.rawValue) { tier in
                                Text(tier.displayName).tag(tier)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    // Usage warning example
                    UsageLimitWarning(
                        currentUsage: 8,
                        limit: 10,
                        title: "Monthly SIF Usage",
                        upgradeAction: {
                            showingTierSelection = true
                        }
                    )
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
            }
            .background(Color.mainAppGradient)
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingTierSelection) {
            TierSelectionView(isUpgradeFlow: true)
        }
    }
}

struct UIComponentShowcase_Previews: PreviewProvider {
    static var previews: some View {
        UIComponentShowcase()
    }
}