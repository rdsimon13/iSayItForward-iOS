import Foundation

// MARK: - User Tier System
enum UserTier: String, CaseIterable, Codable {
    case free = "free"
    case premium = "premium"
    case pro = "pro"
    
    var displayName: String {
        switch self {
        case .free: return "Free"
        case .premium: return "Premium"
        case .pro: return "Pro"
        }
    }
    
    var description: String {
        switch self {
        case .free: return "Basic features, ads, limited data, no e-signature"
        case .premium: return "No ads, increased data limits, includes e-signature"
        case .pro: return "Highest data limits, priority features, no ads, includes e-signature"
        }
    }
    
    var price: String {
        switch self {
        case .free: return "Free"
        case .premium: return "$9.99/month"
        case .pro: return "$19.99/month"
        }
    }
    
    var features: [String] {
        switch self {
        case .free:
            return [
                "Basic SIF creation",
                "Template access",
                "Limited data storage (100MB)",
                "Ads supported"
            ]
        case .premium:
            return [
                "All Free features",
                "No advertisements",
                "E-signature support",
                "Increased storage (1GB)",
                "Priority templates"
            ]
        case .pro:
            return [
                "All Premium features",
                "Unlimited storage",
                "Priority support",
                "Advanced scheduling",
                "Custom branding",
                "Analytics dashboard"
            ]
        }
    }
    
    // MARK: - Feature Gating
    var allowsESignature: Bool {
        switch self {
        case .free: return false
        case .premium, .pro: return true
        }
    }
    
    var showsAds: Bool {
        switch self {
        case .free: return true
        case .premium, .pro: return false
        }
    }
    
    var dataLimitMB: Int {
        switch self {
        case .free: return 100
        case .premium: return 1024 // 1GB
        case .pro: return -1 // Unlimited
        }
    }
    
    var maxSIFsPerMonth: Int {
        switch self {
        case .free: return 10
        case .premium: return 50
        case .pro: return -1 // Unlimited
        }
    }
}

// MARK: - Tier Comparison Helper
extension UserTier {
    func isHigherThan(_ other: UserTier) -> Bool {
        let tierOrder: [UserTier] = [.free, .premium, .pro]
        guard let selfIndex = tierOrder.firstIndex(of: self),
              let otherIndex = tierOrder.firstIndex(of: other) else {
            return false
        }
        return selfIndex > otherIndex
    }
    
    func canAccessFeature(requiredTier: UserTier) -> Bool {
        return self == requiredTier || self.isHigherThan(requiredTier)
    }
}