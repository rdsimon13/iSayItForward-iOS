import Foundation

// MARK: - Date Range Filter
struct DateRangeFilter: Codable, Equatable {
    let startDate: Date?
    let endDate: Date?
    
    var isActive: Bool {
        startDate != nil || endDate != nil
    }
    
    func matches(date: Date) -> Bool {
        if let start = startDate, date < start {
            return false
        }
        if let end = endDate, date > end {
            return false
        }
        return true
    }
}

// MARK: - Impact Score Filter
struct ImpactScoreFilter: Codable, Equatable {
    let minimumScore: Double
    let maximumScore: Double
    
    init(minimumScore: Double = 0.0, maximumScore: Double = 10.0) {
        self.minimumScore = minimumScore
        self.maximumScore = maximumScore
    }
    
    var isActive: Bool {
        minimumScore > 0.0 || maximumScore < 10.0
    }
    
    func matches(score: Double) -> Bool {
        return score >= minimumScore && score <= maximumScore
    }
}

// MARK: - Location Filter
struct LocationFilter: Codable, Equatable {
    let radius: Double? // in kilometers
    let latitude: Double?
    let longitude: Double?
    let placeName: String?
    
    var isActive: Bool {
        radius != nil && latitude != nil && longitude != nil
    }
}

// MARK: - Search Filter Configuration
struct SearchFilter: Codable, Equatable {
    // Content type filters
    var resultTypes: Set<SearchResultType>
    
    // Date filters
    var dateRange: DateRangeFilter
    
    // Category filters
    var categories: Set<String>
    
    // Impact score filter
    var impactScore: ImpactScoreFilter
    
    // Location filter
    var location: LocationFilter?
    
    // User-specific filters
    var authorUids: Set<String>
    var excludeOwnContent: Bool
    
    // Template-specific filters
    var templateCategories: Set<String>
    
    // Message-specific filters
    var hasAttachments: Bool?
    var isScheduled: Bool?
    
    // Status filters
    var includeArchived: Bool
    var includeDrafts: Bool
    
    // Sorting and pagination
    var sortBy: SearchSortOption
    var sortOrder: SearchSortOrder
    
    init() {
        self.resultTypes = Set(SearchResultType.allCases)
        self.dateRange = DateRangeFilter(startDate: nil, endDate: nil)
        self.categories = Set<String>()
        self.impactScore = ImpactScoreFilter()
        self.location = nil
        self.authorUids = Set<String>()
        self.excludeOwnContent = false
        self.templateCategories = Set<String>()
        self.hasAttachments = nil
        self.isScheduled = nil
        self.includeArchived = false
        self.includeDrafts = false
        self.sortBy = .relevance
        self.sortOrder = .descending
    }
    
    // MARK: - Filter State
    var hasActiveFilters: Bool {
        return !resultTypes.isEmpty &&
               dateRange.isActive ||
               !categories.isEmpty ||
               impactScore.isActive ||
               location?.isActive == true ||
               !authorUids.isEmpty ||
               excludeOwnContent ||
               !templateCategories.isEmpty ||
               hasAttachments != nil ||
               isScheduled != nil ||
               !includeArchived ||
               !includeDrafts
    }
    
    var activeFilterCount: Int {
        var count = 0
        if dateRange.isActive { count += 1 }
        if !categories.isEmpty { count += 1 }
        if impactScore.isActive { count += 1 }
        if location?.isActive == true { count += 1 }
        if !authorUids.isEmpty { count += 1 }
        if excludeOwnContent { count += 1 }
        if !templateCategories.isEmpty { count += 1 }
        if hasAttachments != nil { count += 1 }
        if isScheduled != nil { count += 1 }
        if !includeArchived { count += 1 }
        if !includeDrafts { count += 1 }
        return count
    }
    
    // MARK: - Filter Methods
    func matches(result: SearchResult) -> Bool {
        // Check result type
        if !resultTypes.contains(result.type) {
            return false
        }
        
        // Check date range
        if dateRange.isActive && !dateRange.matches(date: result.lastModified) {
            return false
        }
        
        // Check categories (for message and template results)
        if !categories.isEmpty {
            switch result.type {
            case .message, .template:
                if let categoryName = result.categoryName,
                   !categories.contains(categoryName) {
                    return false
                }
            default:
                break
            }
        }
        
        // Check template categories
        if !templateCategories.isEmpty && result.type == .template {
            if let categoryName = result.categoryName,
               !templateCategories.contains(categoryName) {
                return false
            }
        }
        
        // Check author filters
        if !authorUids.isEmpty {
            if let authorUid = result.authorUid,
               !authorUids.contains(authorUid) {
                return false
            }
        }
        
        // Check impact score
        if impactScore.isActive && !impactScore.matches(score: result.score) {
            return false
        }
        
        return true
    }
    
    mutating func clearAllFilters() {
        self = SearchFilter()
    }
    
    mutating func resetToDefaults() {
        self = SearchFilter()
    }
}

// MARK: - Search Sort Options
enum SearchSortOption: String, CaseIterable, Codable {
    case relevance = "relevance"
    case date = "date"
    case title = "title"
    case author = "author"
    case category = "category"
    case score = "score"
    
    var displayName: String {
        switch self {
        case .relevance: return "Relevance"
        case .date: return "Date"
        case .title: return "Title"
        case .author: return "Author"
        case .category: return "Category"
        case .score: return "Impact Score"
        }
    }
}

enum SearchSortOrder: String, CaseIterable, Codable {
    case ascending = "asc"
    case descending = "desc"
    
    var displayName: String {
        switch self {
        case .ascending: return "Ascending"
        case .descending: return "Descending"
        }
    }
}

// MARK: - Predefined Filter Presets
extension SearchFilter {
    
    static var recentMessages: SearchFilter {
        var filter = SearchFilter()
        filter.resultTypes = [.message]
        filter.dateRange = DateRangeFilter(
            startDate: Calendar.current.date(byAdding: .day, value: -7, to: Date()),
            endDate: nil
        )
        filter.sortBy = .date
        return filter
    }
    
    static var myContent: SearchFilter {
        var filter = SearchFilter()
        filter.excludeOwnContent = false
        filter.sortBy = .date
        return filter
    }
    
    static var templates: SearchFilter {
        var filter = SearchFilter()
        filter.resultTypes = [.template]
        filter.sortBy = .category
        return filter
    }
    
    static var users: SearchFilter {
        var filter = SearchFilter()
        filter.resultTypes = [.user]
        filter.sortBy = .title
        return filter
    }
    
    static var scheduledContent: SearchFilter {
        var filter = SearchFilter()
        filter.resultTypes = [.message]
        filter.isScheduled = true
        filter.sortBy = .date
        return filter
    }
}