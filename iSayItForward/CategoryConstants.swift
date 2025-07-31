import Foundation

struct CategoryConstants {
    // MARK: - Collection Names
    static let categoriesCollection = "categories"
    static let tagsCollection = "tags"
    static let categoryStatsCollection = "categoryStats"
    static let categorySubscriptionsCollection = "categorySubscriptions"
    static let sifsCollection = "sifs"
    
    // MARK: - Limits
    static let maxTagsPerMessage = 10
    static let maxTagLength = 30
    static let minTagLength = 2
    static let maxCategoryNameLength = 50
    static let maxCategoryDescriptionLength = 200
    static let maxRelatedTags = 20
    
    // MARK: - Cache Settings
    static let categoryListCacheTimeout: TimeInterval = 300 // 5 minutes
    static let tagSuggestionsCacheTimeout: TimeInterval = 60 // 1 minute
    static let statsRefreshInterval: TimeInterval = 3600 // 1 hour
    
    // MARK: - Suggestion Engine
    static let minSuggestionConfidence: Double = 0.3
    static let maxSuggestionsReturned = 8
    static let contentAnalysisMinWords = 3
    static let trendingTagsTimeWindow: TimeInterval = 86400 * 7 // 7 days
    
    // MARK: - UI Constants
    static let categoryGridColumns = 2
    static let tagCloudMaxTags = 50
    static let categoryIconSize: CGFloat = 24
    static let tagFontSizeRange = (12.0, 24.0)
    
    // MARK: - Colors
    static let defaultCategoryColors = [
        "#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4",
        "#FFEAA7", "#DDA0DD", "#98D8C8", "#F7DC6F",
        "#BB8FCE", "#85C1E9", "#F8C471", "#82E0AA"
    ]
    
    // MARK: - System Categories
    static let systemCategoryNames = [
        "encouragement", "celebration", "sympathy", 
        "announcement", "holiday", "gratitude"
    ]
    
    // MARK: - Reserved Tags
    static let reservedTagNames = [
        "admin", "system", "test", "debug", "internal"
    ]
    
    // MARK: - Error Messages
    struct ErrorMessages {
        static let categoryNotFound = "Category not found"
        static let tagNotFound = "Tag not found"
        static let invalidTagName = "Tag name is invalid"
        static let tagTooLong = "Tag name is too long"
        static let tagTooShort = "Tag name is too short"
        static let tooManyTags = "Too many tags selected"
        static let duplicateTag = "Tag already exists"
        static let reservedTagName = "Tag name is reserved"
        static let networkError = "Network connection error"
        static let permissionDenied = "Permission denied"
    }
    
    // MARK: - Default Values
    struct Defaults {
        static let categoryIcon = "folder.fill"
        static let categoryColor = "#4ECDC4"
        static let tagColor = "#95A5A6"
        static let maxRecentTags = 10
        static let suggestionTimeout: TimeInterval = 2.0
    }
}

// MARK: - Category Helper Functions
extension CategoryConstants {
    static func isSystemCategory(_ name: String) -> Bool {
        systemCategoryNames.contains(name.lowercased())
    }
    
    static func isReservedTag(_ name: String) -> Bool {
        reservedTagNames.contains(name.lowercased())
    }
    
    static func getRandomCategoryColor() -> String {
        defaultCategoryColors.randomElement() ?? Defaults.categoryColor
    }
    
    static func validateCategoryName(_ name: String) -> Bool {
        !name.isEmpty && 
        name.count <= maxCategoryNameLength &&
        name.trimmingCharacters(in: .whitespacesAndNewlines).count > 0
    }
}