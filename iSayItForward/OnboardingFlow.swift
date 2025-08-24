import SwiftUI

// MARK: - Onboarding Flow
struct OnboardingFlow: View {
    @State private var currentPage = 0
    @State private var showingTierSelection = false
    let onComplete: () -> Void
    
    private let pages = OnboardingPage.allPages
    
    var body: some View {
        ZStack {
            Color.mainAppGradient.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Page indicator
                HStack {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.brandBlue : Color.brandBlue.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut(duration: 0.3), value: currentPage)
                    }
                }
                .padding(.top, 60)
                .padding(.bottom, 40)
                
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.5), value: currentPage)
                
                // Navigation buttons
                VStack(spacing: 16) {
                    if currentPage < pages.count - 1 {
                        Button("Continue") {
                            withAnimation {
                                currentPage += 1
                            }
                        }
                        .buttonStyle(ModernPrimaryButtonStyle())
                        
                        Button("Skip") {
                            showingTierSelection = true
                        }
                        .buttonStyle(ModernTertiaryButtonStyle())
                    } else {
                        Button("Choose Your Plan") {
                            showingTierSelection = true
                        }
                        .buttonStyle(ModernPrimaryButtonStyle(
                            gradient: Color.premiumGradient
                        ))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 60)
            }
        }
        .sheet(isPresented: $showingTierSelection) {
            TierSelectionView(isUpgradeFlow: false)
                .onDisappear {
                    onComplete()
                }
        }
    }
}

// MARK: - Onboarding Page Model
struct OnboardingPage {
    let title: String
    let subtitle: String
    let iconName: String
    let gradient: LinearGradient
    let features: [String]
    
    static let allPages = [
        OnboardingPage(
            title: "Welcome to\niSayItForward",
            subtitle: "The ultimate way to express yourself and share meaningful messages with the people you care about.",
            iconName: "heart.text.square.fill",
            gradient: Color.primaryGradient,
            features: [
                "Create beautiful SIFs",
                "Schedule future delivery",
                "Share with individuals or groups"
            ]
        ),
        OnboardingPage(
            title: "Choose Your\nExperience",
            subtitle: "Select from three tiers designed to fit your needs, from basic messaging to premium features.",
            iconName: "crown.fill",
            gradient: Color.premiumGradient,
            features: [
                "Free: Basic features with ads",
                "Premium: Ad-free with e-signatures",
                "Pro: Unlimited everything"
            ]
        ),
        OnboardingPage(
            title: "Powerful\nFeatures",
            subtitle: "Unlock advanced capabilities like e-signatures, unlimited storage, and priority support.",
            iconName: "bolt.fill",
            gradient: Color.proGradient,
            features: [
                "E-signature support",
                "Advanced scheduling",
                "Analytics dashboard",
                "Priority customer support"
            ]
        ),
        OnboardingPage(
            title: "Ready to\nGet Started?",
            subtitle: "Choose your plan and start creating meaningful connections through iSayItForward.",
            iconName: "rocket.fill",
            gradient: Color.primaryGradient,
            features: [
                "Start with Free plan",
                "Upgrade anytime",
                "Cancel whenever you want",
                "30-day money-back guarantee"
            ]
        )
    ]
}

// MARK: - Onboarding Page View
struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Icon with gradient background
                ZStack {
                    Circle()
                        .fill(page.gradient)
                        .frame(width: 120, height: 120)
                        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                    
                    Image(systemName: page.iconName)
                        .font(.system(size: 48, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                // Text content
                VStack(spacing: 16) {
                    Text(page.title)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.neutralGray800)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                    
                    Text(page.subtitle)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.neutralGray600)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .padding(.horizontal, 20)
                }
                
                // Features list
                ModernCard {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(page.features, id: \.self) { feature in
                            HStack(alignment: .top, spacing: 12) {
                                Circle()
                                    .fill(page.gradient)
                                    .frame(width: 8, height: 8)
                                    .padding(.top, 6)
                                
                                Text(feature)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.neutralGray700)
                                    .multilineTextAlignment(.leading)
                                
                                Spacer()
                            }
                        }
                    }
                    .padding(24)
                }
                .padding(.horizontal, 24)
                
                Spacer(minLength: 20)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
        }
    }
}

// MARK: - Quick Start Guide
struct QuickStartGuide: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Text("Quick Start Guide")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.neutralGray800)
                        
                        Text("Get up and running with iSayItForward in minutes")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.neutralGray600)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)
                    
                    // Steps
                    VStack(spacing: 16) {
                        QuickStartStep(
                            number: 1,
                            title: "Choose Your Plan",
                            description: "Select Free, Premium, or Pro based on your needs",
                            iconName: "1.circle.fill",
                            color: .brandBlue
                        )
                        
                        QuickStartStep(
                            number: 2,
                            title: "Create Your First SIF",
                            description: "Tap 'Create SIF' and compose your message",
                            iconName: "2.circle.fill",
                            color: .brandGold
                        )
                        
                        QuickStartStep(
                            number: 3,
                            title: "Add Recipients",
                            description: "Choose single, multiple, or group recipients",
                            iconName: "3.circle.fill",
                            color: .successGreen
                        )
                        
                        QuickStartStep(
                            number: 4,
                            title: "Schedule or Send",
                            description: "Send immediately or schedule for later delivery",
                            iconName: "4.circle.fill",
                            color: .tierPro
                        )
                    }
                    
                    // Tips section
                    ModernCard {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "lightbulb.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.brandGold)
                                
                                Text("Pro Tips")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.neutralGray800)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                TipItem(text: "Use templates to speed up SIF creation")
                                TipItem(text: "Schedule recurring messages for special occasions")
                                TipItem(text: "Try e-signatures for important documents (Premium+)")
                                TipItem(text: "Check analytics to see engagement (Pro)")
                            }
                        }
                        .padding(20)
                    }
                    
                    Button("Get Started") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .buttonStyle(ModernPrimaryButtonStyle())
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
            }
            .background(Color.mainAppGradient)
            .navigationTitle("Getting Started")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// MARK: - Quick Start Step
struct QuickStartStep: View {
    let number: Int
    let title: String
    let description: String
    let iconName: String
    let color: Color
    
    var body: some View {
        ModernCard {
            HStack(spacing: 16) {
                Image(systemName: iconName)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.neutralGray800)
                    
                    Text(description)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.neutralGray600)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.neutralGray400)
            }
            .padding(16)
        }
    }
}

// MARK: - Tip Item
struct TipItem: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(Color.brandGold)
                .frame(width: 4, height: 4)
                .padding(.top, 6)
            
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.neutralGray600)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
    }
}

struct OnboardingFlow_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingFlow(onComplete: { })
    }
}