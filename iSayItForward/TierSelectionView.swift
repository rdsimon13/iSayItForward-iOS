import SwiftUI

struct TierSelectionView: View {
    @StateObject private var subscriptionManager = SubscriptionManager()
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedTier: UserTier = .free
    @State private var showingConfirmation = false
    @State private var isUpgrading = false
    
    let isUpgradeFlow: Bool
    
    init(isUpgradeFlow: Bool = false) {
        self.isUpgradeFlow = isUpgradeFlow
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(hex: "#f8fafc"),
                        Color(hex: "#e2e8f0")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            Text(isUpgradeFlow ? "Upgrade Your Plan" : "Choose Your Plan")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .multilineTextAlignment(.center)
                            
                            Text("Select the plan that best fits your needs")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                        
                        // Current tier indicator (only in upgrade flow)
                        if isUpgradeFlow, let currentUser = subscriptionManager.currentUser {
                            HStack {
                                Text("Current Plan:")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                Text(currentUser.effectiveTier.displayName)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.blue)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Tier cards
                        LazyVStack(spacing: 16) {
                            ForEach(UserTier.allCases, id: \.rawValue) { tier in
                                TierCard(
                                    tier: tier,
                                    isSelected: selectedTier == tier,
                                    isCurrentTier: subscriptionManager.currentUser?.effectiveTier == tier,
                                    onSelect: { selectedTier = tier }
                                )
                            }
                        }
                        
                        // Action button
                        VStack(spacing: 12) {
                            Button(action: {
                                if selectedTier == .free {
                                    handleFreeTierSelection()
                                } else {
                                    showingConfirmation = true
                                }
                            }) {
                                HStack {
                                    if isUpgrading {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .foregroundColor(.white)
                                    }
                                    
                                    Text(getActionButtonText())
                                        .font(.system(size: 18, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    selectedTier == subscriptionManager.currentUser?.effectiveTier ?
                                    Color.gray : Color.blue
                                )
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                            }
                            .disabled(
                                isUpgrading ||
                                selectedTier == subscriptionManager.currentUser?.effectiveTier
                            )
                            
                            if isUpgradeFlow {
                                Button("Cancel") {
                                    presentationMode.wrappedValue.dismiss()
                                }
                                .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                if let currentTier = subscriptionManager.currentUser?.effectiveTier {
                    selectedTier = currentTier
                }
            }
            .alert("Confirm Upgrade", isPresented: $showingConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Confirm") {
                    Task {
                        await handleTierUpgrade()
                    }
                }
            } message: {
                Text("Upgrade to \(selectedTier.displayName) for \(selectedTier.price)?")
            }
        }
    }
    
    private func getActionButtonText() -> String {
        if isUpgrading {
            return "Upgrading..."
        }
        
        if selectedTier == subscriptionManager.currentUser?.effectiveTier {
            return "Current Plan"
        }
        
        if selectedTier == .free {
            return "Continue with Free"
        }
        
        return "Upgrade to \(selectedTier.displayName)"
    }
    
    private func handleFreeTierSelection() {
        if isUpgradeFlow {
            Task {
                await handleTierDowngrade()
            }
        } else {
            // For initial selection, just dismiss
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func handleTierUpgrade() async {
        isUpgrading = true
        
        let success = await subscriptionManager.upgradeTier(to: selectedTier)
        
        isUpgrading = false
        
        if success {
            presentationMode.wrappedValue.dismiss()
        }
        // Error handling is done in the SubscriptionManager
    }
    
    private func handleTierDowngrade() async {
        isUpgrading = true
        
        let success = await subscriptionManager.downgradeTier(to: selectedTier)
        
        isUpgrading = false
        
        if success {
            presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Tier Card Component
struct TierCard: View {
    let tier: UserTier
    let isSelected: Bool
    let isCurrentTier: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(tier.displayName)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                            
                            if isCurrentTier {
                                Text("CURRENT")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.green)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }
                        
                        Text(tier.price)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    // Selection indicator
                    Circle()
                        .fill(isSelected ? Color.blue : Color.clear)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                        )
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .opacity(isSelected ? 1 : 0)
                        )
                }
                
                // Description
                Text(tier.description)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                
                // Features
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(tier.features, id: \.self) { feature in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.green)
                                .frame(width: 16)
                            
                            Text(feature)
                                .font(.system(size: 14, weight: .medium))
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                        }
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? Color.blue : Color.gray.opacity(0.2),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .shadow(
                color: isSelected ? Color.blue.opacity(0.2) : Color.black.opacity(0.1),
                radius: isSelected ? 8 : 4,
                y: 2
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
struct TierSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        TierSelectionView()
    }
}