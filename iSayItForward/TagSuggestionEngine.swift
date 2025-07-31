import Foundation
import NaturalLanguage

class TagSuggestionEngine {
    
    // MARK: - Properties
    private let keywordExtractor = KeywordExtractor()
    private let userHistoryAnalyzer = UserHistoryAnalyzer()
    private let popularityAnalyzer = PopularityAnalyzer()
    
    // MARK: - Main Suggestion Method
    func generateSuggestions(
        for content: String,
        category: Category? = nil,
        userHistory: [String] = [],
        existingTags: [String] = []
    ) async -> [TagSuggestion] {
        
        var suggestions: [TagSuggestion] = []
        
        // Content-based suggestions
        let contentSuggestions = await generateContentBasedSuggestions(content)
        suggestions.append(contentsOf: contentSuggestions)
        
        // Category-related suggestions
        if let category = category {
            let categorySuggestions = await generateCategoryBasedSuggestions(category, content: content)
            suggestions.append(contentsOf: categorySuggestions)
        }
        
        // User history based suggestions
        let historySuggestions = await generateHistoryBasedSuggestions(userHistory, content: content)
        suggestions.append(contentsOf: historySuggestions)
        
        // Popular and trending suggestions
        let popularSuggestions = await generatePopularSuggestions(content: content)
        suggestions.append(contentsOf: popularSuggestions)
        
        // Filter out existing tags and duplicates
        let filteredSuggestions = filterAndRankSuggestions(suggestions, existingTags: existingTags)
        
        return Array(filteredSuggestions.prefix(CategoryConstants.maxSuggestionsReturned))
    }
    
    // MARK: - Content-Based Suggestions
    private func generateContentBasedSuggestions(_ content: String) async -> [TagSuggestion] {
        let keywords = keywordExtractor.extractKeywords(from: content)
        
        return keywords.compactMap { keyword in
            guard TagValidation.validateTag(keyword.word).isSuccess else { return nil }
            
            return TagSuggestion(
                tagName: keyword.word.lowercased(),
                confidence: keyword.relevance,
                reason: .contentAnalysis,
                source: .contentKeywords,
                relatedContent: keyword.context,
                messageContent: content,
                categoryContext: nil,
                userHistory: nil
            )
        }
    }
    
    // MARK: - Category-Based Suggestions
    private func generateCategoryBasedSuggestions(_ category: Category, content: String) async -> [TagSuggestion] {
        var suggestions: [TagSuggestion] = []
        
        // Category name as tag
        if TagValidation.validateTag(category.name).isSuccess {
            suggestions.append(TagSuggestion(
                tagName: category.name.lowercased(),
                confidence: 0.8,
                reason: .categoryRelated,
                source: .rulesBased,
                relatedContent: nil,
                messageContent: content,
                categoryContext: category.name,
                userHistory: nil
            ))
        }
        
        // Common tags for this category
        let commonTags = getCommonTagsForCategory(category.name)
        for tag in commonTags {
            suggestions.append(TagSuggestion(
                tagName: tag.lowercased(),
                confidence: 0.6,
                reason: .categoryRelated,
                source: .communityData,
                relatedContent: nil,
                messageContent: content,
                categoryContext: category.name,
                userHistory: nil
            ))
        }
        
        return suggestions
    }
    
    // MARK: - History-Based Suggestions
    private func generateHistoryBasedSuggestions(_ userHistory: [String], content: String) async -> [TagSuggestion] {
        let historyAnalysis = userHistoryAnalyzer.analyzeHistory(userHistory)
        
        return historyAnalysis.frequentTags.map { tag in
            TagSuggestion(
                tagName: tag.lowercased(),
                confidence: 0.7,
                reason: .userHistory,
                source: .userBehavior,
                relatedContent: nil,
                messageContent: content,
                categoryContext: nil,
                userHistory: userHistory
            )
        }
    }
    
    // MARK: - Popular Suggestions
    private func generatePopularSuggestions(content: String) async -> [TagSuggestion] {
        let trendingTags = popularityAnalyzer.getTrendingTags()
        
        return trendingTags.map { tag in
            TagSuggestion(
                tagName: tag.lowercased(),
                confidence: 0.5,
                reason: .popularTrending,
                source: .communityData,
                relatedContent: nil,
                messageContent: content,
                categoryContext: nil,
                userHistory: nil
            )
        }
    }
    
    // MARK: - Filtering and Ranking
    private func filterAndRankSuggestions(_ suggestions: [TagSuggestion], existingTags: [String]) -> [TagSuggestion] {
        let existingSet = Set(existingTags.map { $0.lowercased() })
        
        // Filter duplicates and existing tags
        var seen = Set<String>()
        let filtered = suggestions.compactMap { suggestion -> TagSuggestion? in
            let normalizedTag = suggestion.tagName.lowercased()
            
            guard !existingSet.contains(normalizedTag),
                  !seen.contains(normalizedTag),
                  suggestion.confidence >= CategoryConstants.minSuggestionConfidence else {
                return nil
            }
            
            seen.insert(normalizedTag)
            return suggestion
        }
        
        // Sort by confidence and source priority
        return filtered.sorted { lhs, rhs in
            if lhs.confidence != rhs.confidence {
                return lhs.confidence > rhs.confidence
            }
            return lhs.source.priority > rhs.source.priority
        }
    }
    
    // MARK: - Helper Methods
    private func getCommonTagsForCategory(_ categoryName: String) -> [String] {
        switch categoryName.lowercased() {
        case "encouragement":
            return ["motivation", "support", "positive", "inspiration"]
        case "celebration":
            return ["birthday", "congratulations", "achievement", "milestone"]
        case "sympathy":
            return ["condolences", "support", "comfort", "thoughts"]
        case "announcement":
            return ["news", "update", "important", "information"]
        case "holiday":
            return ["christmas", "thanksgiving", "easter", "newyear"]
        case "gratitude":
            return ["thankyou", "appreciation", "grateful", "thanks"]
        default:
            return []
        }
    }
}

// MARK: - Supporting Classes
class KeywordExtractor {
    struct Keyword {
        let word: String
        let relevance: Double
        let context: String?
    }
    
    func extractKeywords(from text: String) -> [Keyword] {
        guard text.count >= CategoryConstants.contentAnalysisMinWords else { return [] }
        
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text
        
        var keywords: [Keyword] = []
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace]
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass, options: options) { tag, tokenRange in
            
            if let tag = tag, tag == .noun || tag == .adjective || tag == .verb {
                let word = String(text[tokenRange])
                
                if TagValidation.validateTag(word).isSuccess {
                    keywords.append(Keyword(
                        word: word,
                        relevance: calculateRelevance(for: word, in: text),
                        context: extractContext(for: tokenRange, in: text)
                    ))
                }
            }
            
            return true
        }
        
        return keywords.sorted { $0.relevance > $1.relevance }
    }
    
    private func calculateRelevance(for word: String, in text: String) -> Double {
        let wordCount = text.lowercased().components(separatedBy: " ").filter { $0.contains(word.lowercased()) }.count
        let totalWords = text.components(separatedBy: " ").count
        
        guard totalWords > 0 else { return 0.0 }
        
        let frequency = Double(wordCount) / Double(totalWords)
        let lengthFactor = min(1.0, Double(word.count) / 10.0) // Prefer longer words
        
        return frequency * lengthFactor
    }
    
    private func extractContext(for range: Range<String.Index>, in text: String) -> String? {
        // Extract a few words around the keyword for context
        let words = text.components(separatedBy: " ")
        let keyword = String(text[range])
        
        if let index = words.firstIndex(of: keyword) {
            let start = max(0, index - 2)
            let end = min(words.count, index + 3)
            return words[start..<end].joined(separator: " ")
        }
        
        return nil
    }
}

class UserHistoryAnalyzer {
    struct HistoryAnalysis {
        let frequentTags: [String]
        let patterns: [String]
        let preferences: [String: Double]
    }
    
    func analyzeHistory(_ tags: [String]) -> HistoryAnalysis {
        let frequency = Dictionary(tags.map { ($0, 1) }, uniquingKeysWith: +)
        let sortedByFrequency = frequency.sorted { $0.value > $1.value }
        
        return HistoryAnalysis(
            frequentTags: Array(sortedByFrequency.prefix(5).map { $0.key }),
            patterns: findPatterns(in: tags),
            preferences: calculatePreferences(from: frequency)
        )
    }
    
    private func findPatterns(in tags: [String]) -> [String] {
        // Simple pattern detection - in practice this would be more sophisticated
        return []
    }
    
    private func calculatePreferences(from frequency: [String: Int]) -> [String: Double] {
        let total = frequency.values.reduce(0, +)
        guard total > 0 else { return [:] }
        
        return frequency.mapValues { Double($0) / Double(total) }
    }
}

class PopularityAnalyzer {
    func getTrendingTags() -> [String] {
        // Mock trending tags - in practice this would query the database
        return ["trending", "popular", "viral", "hot", "new"]
    }
    
    func getPopularTagsForTimeframe(_ timeframe: TimeInterval) -> [String] {
        // Mock implementation
        return ["recent", "week", "month", "year"]
    }
}