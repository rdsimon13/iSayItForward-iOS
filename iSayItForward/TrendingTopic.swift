import Foundation

// MARK: - Trending Topic Model
struct TrendingTopic: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let description: String?
    let category: String
    let searchCount: Int
    let trendScore: Double // Algorithm-calculated trending score
    let timeframe: TrendingTimeframe
    let relatedTerms: [String]
    let firstSeen: Date
    let lastUpdated: Date
    let metadata: [String: String]?
    
    init(name: String, description: String? = nil, category: String, searchCount: Int, trendScore: Double, timeframe: TrendingTimeframe, relatedTerms: [String] = []) {
        self.id = UUID().uuidString
        self.name = name
        self.description = description
        self.category = category
        self.searchCount = searchCount
        self.trendScore = trendScore
        self.timeframe = timeframe
        self.relatedTerms = relatedTerms
        self.firstSeen = Date()
        self.lastUpdated = Date()
        self.metadata = nil
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: TrendingTopic, rhs: TrendingTopic) -> Bool {
        lhs.id == rhs.id
    }
    
    // Display helpers
    var formattedSearchCount: String {
        if searchCount >= 1000 {
            return String(format: "%.1fK", Double(searchCount) / 1000.0)
        }
        return "\(searchCount)"
    }
    
    var trendIndicator: TrendDirection {
        if trendScore > 2.0 {
            return .up
        } else if trendScore < 0.5 {
            return .down
        } else {
            return .stable
        }
    }
}

// MARK: - Trending Timeframe
enum TrendingTimeframe: String, CaseIterable, Codable {
    case hour = "hour"
    case day = "day"
    case week = "week"
    case month = "month"
    
    var displayName: String {
        switch self {
        case .hour: return "Trending Now"
        case .day: return "Today"
        case .week: return "This Week"
        case .month: return "This Month"
        }
    }
    
    var duration: TimeInterval {
        switch self {
        case .hour: return 3600
        case .day: return 86400
        case .week: return 604800
        case .month: return 2592000
        }
    }
}

// MARK: - Trend Direction
enum TrendDirection: String, CaseIterable {
    case up = "up"
    case down = "down"
    case stable = "stable"
    
    var symbol: String {
        switch self {
        case .up: return "↗"
        case .down: return "↘"
        case .stable: return "→"
        }
    }
    
    var color: String {
        switch self {
        case .up: return "green"
        case .down: return "red"
        case .stable: return "gray"
        }
    }
}

// MARK: - Featured User Model
struct FeaturedUser: Identifiable, Codable, Hashable {
    let id: String
    let userUid: String
    let name: String
    let email: String?
    let profileImageUrl: String?
    let messageCount: Int
    let impactScore: Double
    let followerCount: Int
    let featuredReason: String // Why this user is featured
    let category: String? // User's primary category
    let joinDate: Date
    let lastActive: Date
    let isVerified: Bool
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: FeaturedUser, rhs: FeaturedUser) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Recommended Content Model
struct RecommendedContent: Identifiable, Codable, Hashable {
    let id: String
    let contentId: String
    let contentType: SearchResultType
    let title: String
    let description: String?
    let thumbnailUrl: String?
    let authorName: String?
    let category: String
    let recommendationScore: Double
    let recommendationReason: String
    let createdDate: Date
    let engagement: ContentEngagement
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: RecommendedContent, rhs: RecommendedContent) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Content Engagement Model
struct ContentEngagement: Codable {
    let viewCount: Int
    let shareCount: Int
    let favoriteCount: Int
    let commentCount: Int
    let averageRating: Double
    
    var totalEngagement: Int {
        viewCount + shareCount + favoriteCount + commentCount
    }
    
    var engagementRate: Double {
        guard viewCount > 0 else { return 0 }
        return Double(shareCount + favoriteCount + commentCount) / Double(viewCount)
    }
}

// MARK: - Popular Category Model
struct PopularCategory: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let displayName: String
    let description: String?
    let iconName: String?
    let color: String?
    let messageCount: Int
    let userCount: Int
    let popularityScore: Double
    let trendDirection: TrendDirection
    let subcategories: [String]
    let lastUpdated: Date
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: PopularCategory, rhs: PopularCategory) -> Bool {
        lhs.id == rhs.id
    }
    
    var formattedMessageCount: String {
        if messageCount >= 1000 {
            return String(format: "%.1fK messages", Double(messageCount) / 1000.0)
        }
        return "\(messageCount) messages"
    }
}

// MARK: - Discovery Section Model
struct DiscoverySection: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String?
    let type: DiscoverySectionType
    let items: [any DiscoveryItem]
    let isExpandable: Bool
    let maxItemsToShow: Int
    
    init(title: String, subtitle: String? = nil, type: DiscoverySectionType, items: [any DiscoveryItem], isExpandable: Bool = false, maxItemsToShow: Int = 5) {
        self.title = title
        self.subtitle = subtitle
        self.type = type
        self.items = items
        self.isExpandable = isExpandable
        self.maxItemsToShow = maxItemsToShow
    }
}

// MARK: - Discovery Section Type
enum DiscoverySectionType: String, CaseIterable {
    case trending = "trending"
    case popular = "popular"
    case featured = "featured"
    case recommended = "recommended"
    case categories = "categories"
    case users = "users"
    case recent = "recent"
    
    var displayName: String {
        switch self {
        case .trending: return "Trending Now"
        case .popular: return "Popular"
        case .featured: return "Featured"
        case .recommended: return "Recommended for You"
        case .categories: return "Popular Categories"
        case .users: return "Featured Users"
        case .recent: return "Recently Active"
        }
    }
}

// MARK: - Discovery Item Protocol
protocol DiscoveryItem: Identifiable, Hashable {
    var id: String { get }
    var title: String { get }
    var subtitle: String? { get }
    var imageUrl: String? { get }
}

// Make our models conform to DiscoveryItem
extension TrendingTopic: DiscoveryItem {
    var title: String { name }
    var subtitle: String? { description }
    var imageUrl: String? { nil }
}

extension FeaturedUser: DiscoveryItem {
    var title: String { name }
    var subtitle: String? { featuredReason }
    var imageUrl: String? { profileImageUrl }
}

extension RecommendedContent: DiscoveryItem {
    var title: String { title }
    var subtitle: String? { description }
    var imageUrl: String? { thumbnailUrl }
}

extension PopularCategory: DiscoveryItem {
    var title: String { displayName }
    var subtitle: String? { description }
    var imageUrl: String? { nil }
}

// MARK: - Mock Data for Development
extension TrendingTopic {
    static let mockData: [TrendingTopic] = [
        TrendingTopic(name: "Birthday Wishes", description: "Heartfelt birthday messages", category: "Celebrations", searchCount: 1250, trendScore: 3.2, timeframe: .day, relatedTerms: ["birthday", "celebration", "wishes"]),
        TrendingTopic(name: "Graduation", description: "Congratulatory messages for graduates", category: "Achievements", searchCount: 890, trendScore: 2.8, timeframe: .week, relatedTerms: ["graduation", "achievement", "congratulations"]),
        TrendingTopic(name: "Thank You", description: "Gratitude and appreciation messages", category: "Gratitude", searchCount: 675, trendScore: 2.1, timeframe: .day, relatedTerms: ["thanks", "gratitude", "appreciation"]),
        TrendingTopic(name: "Holiday Greetings", description: "Seasonal and holiday messages", category: "Holidays", searchCount: 432, trendScore: 1.9, timeframe: .month, relatedTerms: ["holiday", "season", "greetings"])
    ]
}

extension PopularCategory {
    static let mockData: [PopularCategory] = [
        PopularCategory(id: "celebrations", name: "celebrations", displayName: "Celebrations", description: "Birthday parties, anniversaries, and special occasions", iconName: "party.popper", color: "purple", messageCount: 2456, userCount: 890, popularityScore: 9.2, trendDirection: .up, subcategories: ["birthdays", "anniversaries", "parties"], lastUpdated: Date()),
        PopularCategory(id: "gratitude", name: "gratitude", displayName: "Gratitude", description: "Thank you messages and appreciation", iconName: "heart", color: "red", messageCount: 1823, userCount: 654, popularityScore: 8.7, trendDirection: .up, subcategories: ["thanks", "appreciation", "recognition"], lastUpdated: Date()),
        PopularCategory(id: "support", name: "support", displayName: "Support", description: "Encouragement and motivation", iconName: "hands.sparkles", color: "blue", messageCount: 1456, userCount: 523, popularityScore: 8.1, trendDirection: .stable, subcategories: ["encouragement", "motivation", "comfort"], lastUpdated: Date())
    ]
}