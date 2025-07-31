import Foundation
import FirebaseFirestore

struct CategoryStats: Identifiable, Codable {
    @DocumentID var id: String?
    
    let categoryId: String
    let userId: String?
    let period: StatsPeriod
    
    // Usage metrics
    var messageCount: Int = 0
    var viewCount: Int = 0
    var shareCount: Int = 0
    var likeCount: Int = 0
    
    // Time-based metrics
    let startDate: Date
    let endDate: Date
    let lastUpdated: Date
    
    // Engagement metrics
    var avgEngagementRate: Double = 0.0
    var peakUsageHour: Int = 12
    var topTags: [String] = []
    
    init(categoryId: String, userId: String?, period: StatsPeriod) {
        self.categoryId = categoryId
        self.userId = userId
        self.period = period
        self.startDate = period.startDate
        self.endDate = period.endDate
        self.lastUpdated = Date()
    }
}

enum StatsPeriod: String, Codable, CaseIterable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case yearly = "yearly"
    case allTime = "all_time"
    
    var startDate: Date {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .daily:
            return calendar.startOfDay(for: now)
        case .weekly:
            return calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        case .monthly:
            return calendar.dateInterval(of: .month, for: now)?.start ?? now
        case .yearly:
            return calendar.dateInterval(of: .year, for: now)?.start ?? now
        case .allTime:
            return Date.distantPast
        }
    }
    
    var endDate: Date {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) ?? now
        case .weekly:
            return calendar.dateInterval(of: .weekOfYear, for: now)?.end ?? now
        case .monthly:
            return calendar.dateInterval(of: .month, for: now)?.end ?? now
        case .yearly:
            return calendar.dateInterval(of: .year, for: now)?.end ?? now
        case .allTime:
            return Date.distantFuture
        }
    }
    
    var displayName: String {
        switch self {
        case .daily: return "Today"
        case .weekly: return "This Week"
        case .monthly: return "This Month"
        case .yearly: return "This Year"
        case .allTime: return "All Time"
        }
    }
}