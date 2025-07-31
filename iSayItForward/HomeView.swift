import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// MARK: - HomeLaunchpadView with Modern Design
private struct HomeLaunchpadView: View {
    @StateObject private var subscriptionManager = SubscriptionManager()
    @State private var showingTierSelection = false

    var body: some View {
        ZStack {
            Color.mainAppGradient.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Welcome header with tier info
                    ModernCard {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Welcome to iSIF")
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .foregroundColor(.neutralGray800)
                                    
                                    if let user = subscriptionManager.currentUser {
                                        Text(user.name)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.neutralGray600)
                                    }
                                }
                                
                                Spacer()
                                
                                if let user = subscriptionManager.currentUser {
                                    TierBadge(tier: user.effectiveTier)
                                }
                            }
                            
                            Text("Choose an option below to get started")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.neutralGray600)
                        }
                        .padding(20)
                    }
                    
                    // Ad banner (if applicable)
                    AdBannerView(subscriptionManager: subscriptionManager)
                    
                    // Main action buttons
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        NavigationLink(destination: Text("Getting Started Screen")) {
                            HomeActionButton(
                                iconName: "figure.walk",
                                title: "Getting Started",
                                color: .brandBlue
                            )
                        }
                        
                        NavigationLink(destination: CreateSIFView()) {
                            HomeActionButton(
                                iconName: "square.and.pencil",
                                title: "Create SIF",
                                color: .brandGold
                            )
                        }
                        
                        NavigationLink(destination: MySIFsView()) {
                            HomeActionButton(
                                iconName: "envelope",
                                title: "My SIFs",
                                color: .brandBlue
                            )
                        }
                    }

                    // Feature cards
                    VStack(spacing: 16) {
                        NavigationLink(destination: TemplateGalleryView()) {
                            ModernFeatureCard(
                                title: "SIF Template Gallery",
                                description: "Explore a variety of ready made templates designed to help you express yourself with style and speed.",
                                iconName: "photo.on.rectangle.angled",
                                gradient: Color.primaryGradient
                            )
                        }

                        NavigationLink(destination: CreateSIFView()) {
                            ModernFeatureCard(
                                title: "Schedule a SIF",
                                description: "Never forget to send greetings on that special day ever again. Schedule your SIF for future delivery today!",
                                iconName: "calendar",
                                gradient: Color.premiumGradient
                            )
                        }
                        
                        // E-signature feature (gated)
                        Button {
                            if subscriptionManager.canAccessFeature(requiredTier: .premium) {
                                // Navigate to e-signature feature
                            } else {
                                showingTierSelection = true
                            }
                        } label: {
                            ModernFeatureCard(
                                title: "E-Signature Support",
                                description: "Add legally binding e-signatures to your SIFs with Premium or Pro plans.",
                                iconName: "signature",
                                gradient: Color.proGradient,
                                requiresTier: .premium,
                                isLocked: !subscriptionManager.canAccessFeature(requiredTier: .premium)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .sheet(isPresented: $showingTierSelection) {
            TierSelectionView(isUpgradeFlow: true)
                .environmentObject(subscriptionManager)
        }
        .onAppear {
            if let uid = Auth.auth().currentUser?.uid {
                Task {
                    await subscriptionManager.fetchUserData(uid: uid)
                }
            }
        }
    }
}

// MARK: - Modern Home Action Button
private struct HomeActionButton: View {
    let iconName: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 60, height: 60)
                    .shadow(color: color.opacity(0.3), radius: 4, y: 2)
                
                Image(systemName: iconName)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.neutralGray700)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Modern Feature Card
private struct ModernFeatureCard: View {
    let title: String
    let description: String
    let iconName: String
    let gradient: LinearGradient
    let requiresTier: UserTier?
    let isLocked: Bool
    
    init(
        title: String,
        description: String,
        iconName: String,
        gradient: LinearGradient,
        requiresTier: UserTier? = nil,
        isLocked: Bool = false
    ) {
        self.title = title
        self.description = description
        self.iconName = iconName
        self.gradient = gradient
        self.requiresTier = requiresTier
        self.isLocked = isLocked
    }
    
    var body: some View {
        ModernCard {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(title)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.neutralGray800)
                        
                        if let tier = requiresTier {
                            TierRequirementBadge(requiredTier: tier)
                        }
                        
                        if isLocked {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.neutralGray400)
                        }
                    }
                    
                    Text(description)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.neutralGray600)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(gradient)
                        .frame(width: 50, height: 50)
                        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                    
                    Image(systemName: iconName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .padding(20)
            .opacity(isLocked ? 0.6 : 1.0)
        }
    }
}

// MARK: - Main HomeView with Modern Tab Bar
struct HomeView: View {
    @StateObject private var subscriptionManager = SubscriptionManager()
    
    var body: some View {
        if #available(iOS 16.0, *) {
            TabView {
                NavigationStack {
                    HomeLaunchpadView()
                }
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }

                CreateSIFView()
                    .tabItem {
                        Image(systemName: "square.and.pencil")
                        Text("Create")
                    }

                TemplateGalleryView()
                    .tabItem {
                        Image(systemName: "doc.on.doc")
                        Text("Templates")
                    }

                MySIFsView()
                    .tabItem {
                        Image(systemName: "envelope")
                        Text("My SIFs")
                    }

                ProfileView()
                    .tabItem {
                        Image(systemName: "person.crop.circle")
                        Text("Profile")
                    }
            }
            .accentColor(.brandBlue)
            .environmentObject(subscriptionManager)
        } else {
            Text("Home requires iOS 16.0 or newer.")
                .multilineTextAlignment(.center)
                .padding()
                .foregroundColor(.errorRed)
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
