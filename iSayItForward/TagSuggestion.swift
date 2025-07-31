import Foundation

struct TagSuggestion: Identifiable, Codable {
    let id = UUID()
    
    let tagName: String
    let confidence: Double // 0.0 - 1.0
    let reason: SuggestionReason
    let source: SuggestionSource
    let relatedContent: String?
    
    // Context for suggestion
    let messageContent: String?
    let categoryContext: String?
    let userHistory: [String]?
    
    var displayText: String {
        "#\(tagName)"
    }
    
    var confidencePercentage: Int {
        Int(confidence * 100)
    }
}

enum SuggestionReason: String, Codable, CaseIterable {
    case contentAnalysis = "content_analysis"
    case userHistory = "user_history"
    case popularTrending = "popular_trending"
    case categoryRelated = "category_related"
    case semanticSimilarity = "semantic_similarity"
    case collaborativeFiltering = "collaborative_filtering"
    
    var displayName: String {
        switch self {
        case .contentAnalysis: return "Based on content"
        case .userHistory: return "From your history"
        case .popularTrending: return "Popular & trending"
        case .categoryRelated: return "Category related"
        case .semanticSimilarity: return "Similar content"
        case .collaborativeFiltering: return "Others also used"
        }
    }
    
    var iconName: String {
        switch self {
        case .contentAnalysis: return "doc.text.magnifyingglass"
        case .userHistory: return "clock.fill"
        case .popularTrending: return "chart.line.uptrend.xyaxis"
        case .categoryRelated: return "folder.fill"
        case .semanticSimilarity: return "brain.head.profile"
        case .collaborativeFiltering: return "person.2.fill"
        }
    }
}

enum SuggestionSource: String, Codable {
    case mlModel = "ml_model"
    case rulesBased = "rules_based"
    case userBehavior = "user_behavior"
    case communityData = "community_data"
    case contentKeywords = "content_keywords"
    
    var priority: Int {
        switch self {
        case .mlModel: return 5
        case .userBehavior: return 4
        case .contentKeywords: return 3
        case .communityData: return 2
        case .rulesBased: return 1
        }
    }
}

// MARK: - TagSuggestion Extensions
extension TagSuggestion {
    static func mock(for content: String) -> [TagSuggestion] {
        let mockSuggestions = [
            TagSuggestion(
                tagName: "birthday",
                confidence: 0.95,
                reason: .contentAnalysis,
                source: .contentKeywords,
                relatedContent: "birthday celebration",
                messageContent: content,
                categoryContext: "celebration",
                userHistory: nil
            ),
            TagSuggestion(
                tagName: "celebration",
                confidence: 0.87,
                reason: .categoryRelated,
                source: .rulesBased,
                relatedContent: nil,
                messageContent: content,
                categoryContext: "celebration",
                userHistory: nil
            ),
            TagSuggestion(
                tagName: "family",
                confidence: 0.72,
                reason: .userHistory,
                source: .userBehavior,
                relatedContent: nil,
                messageContent: content,
                categoryContext: nil,
                userHistory: ["family", "birthday", "love"]
            )
        ]
        
        return mockSuggestions.sorted { $0.confidence > $1.confidence }
    }
}