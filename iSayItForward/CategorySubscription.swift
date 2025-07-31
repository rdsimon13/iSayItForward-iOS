import Foundation
import FirebaseFirestore

struct CategorySubscription: Identifiable, Codable {
    @DocumentID var id: String?
    
    let userId: String
    let categoryId: String
    let subscribedDate: Date
    
    // Subscription preferences
    var isActive: Bool = true
    var notificationEnabled: Bool = true
    var priority: SubscriptionPriority = .normal
    var customSettings: [String: String] = [:]
    
    // Engagement tracking
    var lastViewedDate: Date?
    var totalViews: Int = 0
    var totalShares: Int = 0
    
    init(userId: String, categoryId: String) {
        self.userId = userId
        self.categoryId = categoryId
        self.subscribedDate = Date()
    }
}

enum SubscriptionPriority: String, Codable, CaseIterable {
    case low = "low"
    case normal = "normal"
    case high = "high"
    case critical = "critical"
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var iconName: String {
        switch self {
        case .low: return "circle"
        case .normal: return "circle.fill"
        case .high: return "exclamationmark.circle.fill"
        case .critical: return "alarm.fill"
        }
    }
    
    var sortOrder: Int {
        switch self {
        case .critical: return 4
        case .high: return 3
        case .normal: return 2
        case .low: return 1
        }
    }
}