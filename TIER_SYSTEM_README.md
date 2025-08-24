# iSayItForward Tier System Implementation

## Overview

This implementation adds a comprehensive three-tier subscription system to the iSayItForward iOS app with modern UI components and feature gating.

## Tier Structure

### 🆓 Free Tier
- Basic SIF creation and sending
- Template access
- Limited data storage (100MB)
- 10 SIFs per month
- Ad-supported experience

### 💎 Premium Tier ($9.99/month)
- All Free tier features
- No advertisements
- E-signature support
- Increased storage (1GB)
- 50 SIFs per month
- Priority templates

### 👑 Pro Tier ($19.99/month)
- All Premium tier features
- Unlimited storage and SIFs
- Priority customer support
- Advanced scheduling features
- Analytics dashboard
- Custom branding options

## Key Components

### Core Tier System
- **`UserTier.swift`** - Enum defining tier levels, features, and pricing
- **`SubscriptionManager.swift`** - Manages user subscriptions and Firebase integration
- **`User.swift`** - Updated user model with tier information
- **`TierSelectionView.swift`** - UI for choosing and upgrading tiers

### Feature Gating
- **`FeatureGating.swift`** - Utilities for controlling feature access
- **`UpgradePromptView`** - Encourages upgrades for locked features
- **`TierRequirementBadge`** - Shows required tier for features
- **`UsageLimitWarning`** - Alerts users approaching limits

### Modern UI Components
- **`ModernUIComponents.swift`** - New card, button, and UI styles
- **`Color+Theme.swift`** - Updated color palette and gradients
- **`ModernCard`** - Clean card component with shadows
- **`TierBadge`** - Visual tier indicators

### Updated Views
- **`HomeView.swift`** - Features tier-aware content and upgrade prompts
- **`ProfileView.swift`** - Shows current tier with upgrade options
- **`CreateSIFView.swift`** - Includes e-signature gating and usage warnings
- **`WelcomeView.swift`** - Modern sign-in/up flow
- **`MySIFsView.swift`** - Clean list with tier-based usage stats

## Usage Examples

### Checking Feature Access
```swift
// In any view
@StateObject private var subscriptionManager = SubscriptionManager()

// Check if user can access e-signatures
if subscriptionManager.canAccessFeature(requiredTier: .premium) {
    // Show e-signature UI
} else {
    // Show upgrade prompt
}
```

### Feature Gating with View Modifier
```swift
SomeFeatureView()
    .featureGated(
        requiredTier: .premium,
        subscriptionManager: subscriptionManager,
        upgradeAction: { showTierSelection = true }
    )
```

### Displaying Tier Information
```swift
// Show user's current tier
TierBadge(tier: user.effectiveTier)

// Show requirement for feature
TierRequirementBadge(requiredTier: .premium)
```

### Usage Limits and Warnings
```swift
UsageLimitWarning(
    currentUsage: 8,
    limit: user.effectiveTier.maxSIFsPerMonth,
    title: "Monthly SIFs",
    upgradeAction: { showUpgrade = true }
)
```

## Demo Components

### UI Showcase
- **`UIComponentShowcase.swift`** - Visual preview of all new components
- Demonstrates tier badges, modern cards, buttons
- Shows feature gating in action

### Interactive Demo
- **`TierSystemDemo.swift`** - Interactive tier switching demo
- Live feature access demonstration
- Usage limit simulations

### Onboarding
- **`OnboardingFlow.swift`** - Welcome flow for new users
- **`QuickStartGuide.swift`** - Getting started instructions
- Introduces tier system benefits

## Firebase Integration

### User Data Structure
```swift
// Firestore document structure
{
    "uid": "user_id",
    "name": "User Name", 
    "email": "user@email.com",
    "tier": "premium", // "free", "premium", "pro"
    "tierExpiryDate": timestamp,
    "createdAt": timestamp,
    "lastUpdated": timestamp
}
```

### Subscription Management
```swift
// Upgrade user tier
await subscriptionManager.upgradeTier(to: .premium)

// Check access
let hasAccess = subscriptionManager.canAccessFeature(requiredTier: .premium)

// Get usage info
let dataLimit = subscriptionManager.getRemainingDataAllowance()
let showAds = subscriptionManager.shouldShowAds()
```

## Installation Instructions

1. **Add to Xcode Project**: Include all new Swift files in your project
2. **Firebase Setup**: Ensure Firebase Auth and Firestore are configured
3. **Update Info.plist**: Add any required permissions
4. **Test Integration**: Use demo components to verify functionality

## Customization

### Adding New Tiers
1. Update `UserTier` enum with new case
2. Add features and pricing information
3. Update UI components to handle new tier
4. Test feature gating logic

### Modifying Features
1. Update `UserTier.features` arrays
2. Adjust feature gating in `FeatureGating.swift`
3. Update UI components as needed

### Styling Changes
1. Modify colors in `Color+Theme.swift`
2. Update gradients and component styles
3. Adjust spacing and sizing in `ModernUIComponents.swift`

## Testing

### Manual Testing
1. Use `TierSystemDemo.swift` for interactive testing
2. Switch between tiers to test feature access
3. Verify upgrade/downgrade flows work correctly

### UI Testing
1. Use `UIComponentShowcase.swift` to verify visual consistency
2. Test on different device sizes
3. Verify dark mode compatibility

### Integration Testing
1. Test Firebase data persistence
2. Verify subscription state management
3. Test feature gating edge cases

## Future Enhancements

### Payment Integration
- Add StoreKit for in-app purchases
- Implement subscription validation
- Handle payment failures and restoration

### Analytics
- Track tier conversion rates
- Monitor feature usage by tier
- A/B test upgrade prompts

### Advanced Features
- Implement Pro tier analytics dashboard
- Add custom branding options
- Create advanced scheduling features

## Support

For questions or issues with the tier system implementation:
1. Check demo components for examples
2. Review feature gating utilities
3. Test with different tier configurations
4. Verify Firebase integration is working

The tier system is designed to be extensible and maintainable, with clear separation between tiers and features for easy updates and modifications.