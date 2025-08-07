import Foundation
import FirebaseFirestore

/// Model for storing impact measurement data
struct ImpactMetrics: Identifiable, Codable, Hashable, Equatable {
    @DocumentID var id: String?
    
    let userId: String
    let period: TimePeriod
    let startDate: Date
    let endDate: Date
    
    // Response metrics
    let totalResponses: Int
    let responsesByCategory: [ResponseCategory: Int]
    let averageResponseTime: TimeInterval // in seconds
    let responseRate: Double // percentage of SIFs that received responses
    
    // Impact measurements
    let positiveImpactScore: Double
    let engagementLevel: EngagementLevel
    let reachMetrics: ReachMetrics
    let sentimentAnalysis: SentimentAnalysis
    
    // Signature usage
    let signatureUsageCount: Int
    let documentsSignedCount: Int
    
    // Analytics data
    let generatedDate: Date
    let dataSourceVersion: String
    
    init(userId: String, period: TimePeriod, startDate: Date, endDate: Date) {
        self.userId = userId
        self.period = period
        self.startDate = startDate
        self.endDate = endDate
        self.totalResponses = 0
        self.responsesByCategory = [:]
        self.averageResponseTime = 0
        self.responseRate = 0
        self.positiveImpactScore = 0
        self.engagementLevel = .low
        self.reachMetrics = ReachMetrics()
        self.sentimentAnalysis = SentimentAnalysis()
        self.signatureUsageCount = 0
        self.documentsSignedCount = 0
        self.generatedDate = Date()
        self.dataSourceVersion = "1.0"
    }
    
    // Hashable & Equatable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ImpactMetrics, rhs: ImpactMetrics) -> Bool {
        lhs.id == rhs.id
    }
}

/// Time periods for metrics calculation
enum TimePeriod: String, Codable, CaseIterable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case quarterly = "quarterly"
    case yearly = "yearly"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .daily:
            return "Daily"
        case .weekly:
            return "Weekly"
        case .monthly:
            return "Monthly"
        case .quarterly:
            return "Quarterly"
        case .yearly:
            return "Yearly"
        case .custom:
            return "Custom Range"
        }
    }
}

/// Engagement level classifications
enum EngagementLevel: String, Codable, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case exceptional = "exceptional"
    
    var displayName: String {
        switch self {
        case .low:
            return "Low"
        case .medium:
            return "Medium"
        case .high:
            return "High"
        case .exceptional:
            return "Exceptional"
        }
    }
    
    var color: String {
        switch self {
        case .low:
            return "red"
        case .medium:
            return "orange"
        case .high:
            return "green"
        case .exceptional:
            return "blue"
        }
    }
}

/// Reach and distribution metrics
struct ReachMetrics: Codable, Hashable {
    let uniqueRespondents: Int
    let totalReach: Int
    let shareRate: Double
    let forwardRate: Double
    let geographicDistribution: [String: Int] // Country/Region -> Count
    
    init() {
        self.uniqueRespondents = 0
        self.totalReach = 0
        self.shareRate = 0
        self.forwardRate = 0
        self.geographicDistribution = [:]
    }
}

/// Sentiment analysis results
struct SentimentAnalysis: Codable, Hashable {
    let overallSentiment: SentimentScore
    let positiveResponses: Int
    let neutralResponses: Int
    let negativeResponses: Int
    let emotionalTone: EmotionalTone
    
    init() {
        self.overallSentiment = .neutral
        self.positiveResponses = 0
        self.neutralResponses = 0
        self.negativeResponses = 0
        self.emotionalTone = .neutral
    }
}

/// Sentiment scoring
enum SentimentScore: String, Codable, CaseIterable {
    case veryPositive = "very_positive"
    case positive = "positive"
    case neutral = "neutral"
    case negative = "negative"
    case veryNegative = "very_negative"
    
    var displayName: String {
        switch self {
        case .veryPositive:
            return "Very Positive"
        case .positive:
            return "Positive"
        case .neutral:
            return "Neutral"
        case .negative:
            return "Negative"
        case .veryNegative:
            return "Very Negative"
        }
    }
    
    var score: Double {
        switch self {
        case .veryPositive:
            return 1.0
        case .positive:
            return 0.5
        case .neutral:
            return 0.0
        case .negative:
            return -0.5
        case .veryNegative:
            return -1.0
        }
    }
}

/// Emotional tone categories
enum EmotionalTone: String, Codable, CaseIterable {
    case joyful = "joyful"
    case grateful = "grateful"
    case supportive = "supportive"
    case neutral = "neutral"
    case concerned = "concerned"
    case disappointed = "disappointed"
    case frustrated = "frustrated"
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var iconName: String {
        switch self {
        case .joyful:
            return "face.smiling"
        case .grateful:
            return "heart"
        case .supportive:
            return "hands.clap"
        case .neutral:
            return "minus.circle"
        case .concerned:
            return "exclamationmark.triangle"
        case .disappointed:
            return "face.dashed"
        case .frustrated:
            return "flame"
        }
    }
}