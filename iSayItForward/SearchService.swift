import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

// MARK: - Search Service
class SearchService: ObservableObject {
    @Published var isSearching = false
    @Published var searchResults: [SearchResult] = []
    @Published var suggestions: [String] = []
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    private let cache = SearchCache()
    private let analytics = SearchAnalytics()
    private let suggestionEngine = SearchSuggestionEngine()
    
    // MARK: - Search Methods
    func search(query: String, filters: SearchFilter, completion: @escaping ([SearchResult]) -> Void) {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            completion([])
            return
        }
        
        let cacheKey = createCacheKey(query: query, filters: filters)
        
        // Check cache first
        if let cachedResults = cache.getResults(for: cacheKey) {
            DispatchQueue.main.async {
                self.searchResults = cachedResults
                completion(cachedResults)
            }
            return
        }
        
        isSearching = true
        errorMessage = nil
        
        // Track search analytics
        analytics.trackSearchStarted(query: query, filters: filters)
        
        Task {
            do {
                let results = try await performSearch(query: query, filters: filters)
                
                DispatchQueue.main.async {
                    self.isSearching = false
                    self.searchResults = results
                    
                    // Cache results
                    self.cache.storeResults(results, for: cacheKey)
                    
                    // Track analytics
                    self.analytics.trackSearchCompleted(query: query, resultCount: results.count, filters: filters)
                    
                    completion(results)
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.isSearching = false
                    self.errorMessage = error.localizedDescription
                    self.analytics.trackSearchFailed(query: query, error: error)
                    completion([])
                }
            }
        }
    }
    
    // MARK: - Async Search Implementation
    private func performSearch(query: String, filters: SearchFilter) async throws -> [SearchResult] {
        var allResults: [SearchResult] = []
        
        // Search messages if enabled
        if filters.resultTypes.contains(.message) {
            let messageResults = try await searchMessages(query: query, filters: filters)
            allResults.append(contentsOf: messageResults)
        }
        
        // Search users if enabled
        if filters.resultTypes.contains(.user) {
            let userResults = try await searchUsers(query: query, filters: filters)
            allResults.append(contentsOf: userResults)
        }
        
        // Search templates if enabled
        if filters.resultTypes.contains(.template) {
            let templateResults = try await searchTemplates(query: query, filters: filters)
            allResults.append(contentsOf: templateResults)
        }
        
        // Search categories if enabled
        if filters.resultTypes.contains(.category) {
            let categoryResults = await searchCategories(query: query, filters: filters)
            allResults.append(contentsOf: categoryResults)
        }
        
        // Apply additional filtering
        allResults = allResults.filter { filters.matches(result: $0) }
        
        // Sort results
        allResults = sortResults(allResults, by: filters.sortBy, order: filters.sortOrder)
        
        return allResults
    }
    
    // MARK: - Search Individual Content Types
    private func searchMessages(query: String, filters: SearchFilter) async throws -> [SearchResult] {
        let collection = db.collection("sifs")
        var firebaseQuery: Query = collection
        
        // Apply basic filtering
        if let currentUserUid = Auth.auth().currentUser?.uid, filters.excludeOwnContent {
            firebaseQuery = firebaseQuery.whereField("authorUid", isNotEqualTo: currentUserUid)
        }
        
        if !filters.authorUids.isEmpty {
            firebaseQuery = firebaseQuery.whereField("authorUid", in: Array(filters.authorUids))
        }
        
        // Date filtering
        if let startDate = filters.dateRange.startDate {
            firebaseQuery = firebaseQuery.whereField("createdDate", isGreaterThanOrEqualTo: startDate)
        }
        
        if let endDate = filters.dateRange.endDate {
            firebaseQuery = firebaseQuery.whereField("createdDate", isLessThanOrEqualTo: endDate)
        }
        
        // Execute query
        let snapshot = try await firebaseQuery.getDocuments()
        
        let messages = snapshot.documents.compactMap { document -> SIFItem? in
            try? document.data(as: SIFItem.self)
        }
        
        // Perform text search filtering
        let filteredMessages = messages.filter { message in
            let searchableText = "\(message.subject) \(message.message)".lowercased()
            return searchableText.contains(query.lowercased())
        }
        
        // Convert to search results with relevance scoring
        return filteredMessages.map { message in
            let score = calculateRelevanceScore(for: message, query: query)
            return SearchResultFactory.createMessageResult(from: message, score: score)
        }
    }
    
    private func searchUsers(query: String, filters: SearchFilter) async throws -> [SearchResult] {
        let collection = db.collection("users")
        let snapshot = try await collection.getDocuments()
        
        let users = snapshot.documents.compactMap { document -> User? in
            guard let uid = document.data()["uid"] as? String,
                  let name = document.data()["name"] as? String,
                  let email = document.data()["email"] as? String else {
                return nil
            }
            return User(uid: uid, name: name, email: email)
        }
        
        // Filter users based on query
        let filteredUsers = users.filter { user in
            let searchableText = "\(user.name) \(user.email)".lowercased()
            return searchableText.contains(query.lowercased())
        }
        
        return filteredUsers.map { user in
            let score = calculateUserRelevanceScore(for: user, query: query)
            return SearchResultFactory.createUserResult(from: user, score: score)
        }
    }
    
    private func searchTemplates(query: String, filters: SearchFilter) async throws -> [SearchResult] {
        // Search through the template library
        let templates = TemplateLibrary.templates
        
        let filteredTemplates = templates.filter { template in
            let searchableText = "\(template.name) \(template.message)".lowercased()
            let matchesQuery = searchableText.contains(query.lowercased())
            
            // Apply category filter if specified
            if !filters.templateCategories.isEmpty {
                return matchesQuery && filters.templateCategories.contains(template.category.rawValue)
            }
            
            return matchesQuery
        }
        
        return filteredTemplates.map { template in
            let score = calculateTemplateRelevanceScore(for: template, query: query)
            return SearchResultFactory.createTemplateResult(from: template, score: score)
        }
    }
    
    private func searchCategories(query: String, filters: SearchFilter) async -> [SearchResult] {
        let categories = [
            ("Birthday", "Birthday celebrations and wishes"),
            ("Thank You", "Gratitude and appreciation messages"),
            ("Congratulations", "Achievement and success messages"),
            ("Get Well", "Health and recovery wishes"),
            ("Love & Romance", "Romantic and love messages"),
            ("Friendship", "Friendship and connection messages"),
            ("Holiday", "Holiday and seasonal greetings"),
            ("Sympathy", "Condolence and sympathy messages"),
            ("Motivation", "Inspirational and motivational content"),
            ("Business", "Professional and business communications")
        ]
        
        let filteredCategories = categories.filter { category in
            let searchableText = "\(category.0) \(category.1)".lowercased()
            return searchableText.contains(query.lowercased())
        }
        
        return filteredCategories.map { category in
            SearchResultFactory.createCategoryResult(
                name: category.0,
                description: category.1,
                score: calculateCategoryRelevanceScore(category: category.0, query: query)
            )
        }
    }
    
    // MARK: - Suggestions
    func getSuggestions(for query: String, completion: @escaping ([String]) -> Void) {
        guard query.count >= 2 else {
            completion([])
            return
        }
        
        suggestionEngine.generateSuggestions(for: query) { suggestions in
            DispatchQueue.main.async {
                self.suggestions = suggestions
                completion(suggestions)
            }
        }
    }
    
    // MARK: - Relevance Scoring
    private func calculateRelevanceScore(for message: SIFItem, query: String) -> Double {
        let queryLowercased = query.lowercased()
        var score = 0.0
        
        // Subject match (higher weight)
        if message.subject.lowercased().contains(queryLowercased) {
            score += 3.0
        }
        
        // Exact subject match (highest weight)
        if message.subject.lowercased() == queryLowercased {
            score += 5.0
        }
        
        // Message content match
        if message.message.lowercased().contains(queryLowercased) {
            score += 1.0
        }
        
        // Recency boost (messages from last 30 days get boost)
        let daysSinceCreation = Calendar.current.dateComponents([.day], from: message.createdDate, to: Date()).day ?? 0
        if daysSinceCreation <= 30 {
            score += 1.0 - (Double(daysSinceCreation) / 30.0)
        }
        
        return score
    }
    
    private func calculateUserRelevanceScore(for user: User, query: String) -> Double {
        let queryLowercased = query.lowercased()
        var score = 0.0
        
        // Name match
        if user.name.lowercased().contains(queryLowercased) {
            score += 3.0
        }
        
        // Exact name match
        if user.name.lowercased() == queryLowercased {
            score += 5.0
        }
        
        // Email match
        if user.email.lowercased().contains(queryLowercased) {
            score += 2.0
        }
        
        return score
    }
    
    private func calculateTemplateRelevanceScore(for template: TemplateItem, query: String) -> Double {
        let queryLowercased = query.lowercased()
        var score = 0.0
        
        // Name match
        if template.name.lowercased().contains(queryLowercased) {
            score += 3.0
        }
        
        // Message content match
        if template.message.lowercased().contains(queryLowercased) {
            score += 1.0
        }
        
        // Category match
        if template.category.rawValue.lowercased().contains(queryLowercased) {
            score += 2.0
        }
        
        return score
    }
    
    private func calculateCategoryRelevanceScore(category: String, query: String) -> Double {
        let queryLowercased = query.lowercased()
        
        if category.lowercased() == queryLowercased {
            return 5.0
        } else if category.lowercased().contains(queryLowercased) {
            return 3.0
        }
        
        return 1.0
    }
    
    // MARK: - Sorting
    private func sortResults(_ results: [SearchResult], by sortOption: SearchSortOption, order: SearchSortOrder) -> [SearchResult] {
        return results.sorted { lhs, rhs in
            let comparison: Bool
            
            switch sortOption {
            case .relevance:
                comparison = lhs.score > rhs.score
            case .date:
                comparison = lhs.lastModified > rhs.lastModified
            case .title:
                comparison = lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            case .author:
                let lhsAuthor = lhs.metadata?["authorUid"] ?? ""
                let rhsAuthor = rhs.metadata?["authorUid"] ?? ""
                comparison = lhsAuthor.localizedCaseInsensitiveCompare(rhsAuthor) == .orderedAscending
            case .category:
                let lhsCategory = lhs.categoryName ?? ""
                let rhsCategory = rhs.categoryName ?? ""
                comparison = lhsCategory.localizedCaseInsensitiveCompare(rhsCategory) == .orderedAscending
            case .score:
                comparison = lhs.score > rhs.score
            }
            
            return order == .ascending ? !comparison : comparison
        }
    }
    
    // MARK: - Cache Management
    private func createCacheKey(query: String, filters: SearchFilter) -> String {
        let filtersData = try? JSONEncoder().encode(filters)
        let filtersHash = filtersData?.hashValue ?? 0
        return "\(query.lowercased())_\(filtersHash)"
    }
    
    func clearCache() {
        cache.clearAll()
    }
    
    // MARK: - Error Handling
    enum SearchError: LocalizedError {
        case invalidQuery
        case networkError
        case permissionDenied
        case serverError(String)
        
        var errorDescription: String? {
            switch self {
            case .invalidQuery:
                return "Please enter a valid search query"
            case .networkError:
                return "Network connection error. Please check your internet connection."
            case .permissionDenied:
                return "You don't have permission to access this content"
            case .serverError(let message):
                return "Server error: \(message)"
            }
        }
    }
}

// MARK: - Search Cache
private class SearchCache {
    private var cache: [String: CachedSearchResult] = [:]
    private let maxCacheSize = 50
    private let cacheExpirationTime: TimeInterval = 300 // 5 minutes
    
    struct CachedSearchResult {
        let results: [SearchResult]
        let timestamp: Date
    }
    
    func getResults(for key: String) -> [SearchResult]? {
        guard let cached = cache[key] else { return nil }
        
        // Check if cache is still valid
        if Date().timeIntervalSince(cached.timestamp) > cacheExpirationTime {
            cache.removeValue(forKey: key)
            return nil
        }
        
        return cached.results
    }
    
    func storeResults(_ results: [SearchResult], for key: String) {
        // Remove oldest entries if cache is full
        if cache.count >= maxCacheSize {
            let oldestKey = cache.min { lhs, rhs in
                lhs.value.timestamp < rhs.value.timestamp
            }?.key
            
            if let keyToRemove = oldestKey {
                cache.removeValue(forKey: keyToRemove)
            }
        }
        
        cache[key] = CachedSearchResult(results: results, timestamp: Date())
    }
    
    func clearAll() {
        cache.removeAll()
    }
}