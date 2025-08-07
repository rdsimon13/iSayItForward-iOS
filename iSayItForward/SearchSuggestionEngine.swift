import Foundation
import FirebaseFirestore

// MARK: - Search Suggestion Engine
class SearchSuggestionEngine: ObservableObject {
    @Published var suggestions: [String] = []
    
    private let db = Firestore.firestore()
    private var suggestionCache: [String: [String]] = [:]
    private let maxSuggestions = 8
    
    // Common search terms and phrases
    private let commonSearchTerms = [
        "birthday", "thank you", "congratulations", "get well", "love",
        "anniversary", "graduation", "wedding", "baby", "sympathy",
        "holiday", "christmas", "new year", "valentine", "mother's day",
        "father's day", "thanksgiving", "friendship", "support", "motivation"
    ]
    
    private let searchPatterns = [
        "birthday wishes for",
        "thank you message for",
        "congratulations on",
        "get well soon",
        "happy anniversary",
        "wedding congratulations",
        "new baby wishes",
        "sympathy message",
        "holiday greetings",
        "motivational quotes"
    ]
    
    // MARK: - Generate Suggestions
    func generateSuggestions(for query: String, completion: @escaping ([String]) -> Void) {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        guard !trimmedQuery.isEmpty else {
            completion(getPopularSuggestions())
            return
        }
        
        // Check cache first
        if let cachedSuggestions = suggestionCache[trimmedQuery] {
            completion(Array(cachedSuggestions.prefix(maxSuggestions)))
            return
        }
        
        Task {
            let suggestions = await buildSuggestions(for: trimmedQuery)
            
            DispatchQueue.main.async {
                self.suggestionCache[trimmedQuery] = suggestions
                completion(Array(suggestions.prefix(self.maxSuggestions)))
            }
        }
    }
    
    private func buildSuggestions(for query: String) async -> [String] {
        var suggestions: [String] = []
        
        // 1. Add exact matches from common terms
        suggestions.append(contentsOf: exactMatches(for: query))
        
        // 2. Add prefix matches from common terms
        suggestions.append(contentsOf: prefixMatches(for: query))
        
        // 3. Add pattern-based suggestions
        suggestions.append(contentsOf: patternMatches(for: query))
        
        // 4. Add fuzzy matches
        suggestions.append(contentsOf: fuzzyMatches(for: query))
        
        // 5. Add historical suggestions
        if let historicalSuggestions = await getHistoricalSuggestions(for: query) {
            suggestions.append(contentsOf: historicalSuggestions)
        }
        
        // 6. Add contextual suggestions
        suggestions.append(contentsOf: getContextualSuggestions(for: query))
        
        // Remove duplicates and return
        return Array(OrderedSet(suggestions))
    }
    
    // MARK: - Suggestion Algorithms
    private func exactMatches(for query: String) -> [String] {
        return commonSearchTerms.filter { $0.lowercased() == query }
    }
    
    private func prefixMatches(for query: String) -> [String] {
        return commonSearchTerms.filter { term in
            term.lowercased().hasPrefix(query) && term.lowercased() != query
        }
    }
    
    private func patternMatches(for query: String) -> [String] {
        return searchPatterns.filter { pattern in
            pattern.lowercased().contains(query)
        }
    }
    
    private func fuzzyMatches(for query: String) -> [String] {
        return commonSearchTerms.filter { term in
            let distance = levenshteinDistance(query, term.lowercased())
            return distance <= 2 && distance > 0 && abs(query.count - term.count) <= 3
        }
    }
    
    private func getHistoricalSuggestions(for query: String) async -> [String]? {
        do {
            // Query search history for similar searches
            let snapshot = try await db.collection("analytics")
                .document("searches")
                .collection("popular_queries")
                .whereField("query", isGreaterThanOrEqualTo: query)
                .whereField("query", isLessThan: query + "z")
                .limit(to: 5)
                .getDocuments()
            
            return snapshot.documents.compactMap { document in
                document.data()["query"] as? String
            }
            
        } catch {
            print("Error fetching historical suggestions: \(error)")
            return nil
        }
    }
    
    private func getContextualSuggestions(for query: String) -> [String] {
        let currentMonth = Calendar.current.component(.month, from: Date())
        let currentDay = Calendar.current.component(.day, from: Date())
        
        var contextual: [String] = []
        
        // Seasonal suggestions
        switch currentMonth {
        case 12:
            if query.contains("hol") || query.contains("chr") {
                contextual.append(contentsOf: ["christmas wishes", "holiday greetings", "new year messages"])
            }
        case 2:
            if query.contains("val") || query.contains("lov") {
                contextual.append(contentsOf: ["valentine's day", "love messages", "romantic wishes"])
            }
        case 5:
            if query.contains("moth") {
                contextual.append(contentsOf: ["mother's day wishes", "mom appreciation"])
            }
        case 6:
            if query.contains("fath") || query.contains("dad") {
                contextual.append(contentsOf: ["father's day wishes", "dad appreciation"])
            }
        default:
            break
        }
        
        // Common occasions based on query keywords
        if query.contains("birth") {
            contextual.append(contentsOf: ["birthday wishes", "birthday party", "birthday celebration"])
        } else if query.contains("thank") {
            contextual.append(contentsOf: ["thank you note", "appreciation message", "gratitude letter"])
        } else if query.contains("congrat") {
            contextual.append(contentsOf: ["congratulations message", "achievement recognition", "success celebration"])
        } else if query.contains("grad") {
            contextual.append(contentsOf: ["graduation wishes", "graduation congratulations", "academic achievement"])
        } else if query.contains("wedd") {
            contextual.append(contentsOf: ["wedding wishes", "marriage congratulations", "wedding celebration"])
        }
        
        return contextual
    }
    
    private func getPopularSuggestions() -> [String] {
        return [
            "birthday wishes",
            "thank you",
            "congratulations",
            "get well soon",
            "anniversary",
            "graduation",
            "holiday greetings",
            "sympathy"
        ]
    }
    
    // MARK: - Suggestion Learning
    func learnFromSearch(query: String, resultCount: Int, userSelected: Bool) {
        // Track successful searches for future suggestions
        if resultCount > 0 && userSelected {
            updateSuggestionWeight(for: query, weight: 1.0)
        }
    }
    
    func learnFromSelection(selectedSuggestion: String, originalQuery: String) {
        // Boost the selected suggestion for similar future queries
        updateSuggestionWeight(for: selectedSuggestion, weight: 1.5)
        
        // Create association between original query and selected suggestion
        createQueryAssociation(from: originalQuery, to: selectedSuggestion)
    }
    
    private func updateSuggestionWeight(for suggestion: String, weight: Double) {
        let data: [String: Any] = [
            "suggestion": suggestion,
            "weight": FieldValue.increment(weight),
            "lastUsed": Date(),
            "useCount": FieldValue.increment(Int64(1))
        ]
        
        db.collection("analytics")
            .document("suggestions")
            .collection("weights")
            .document(suggestion.replacingOccurrences(of: " ", with: "_"))
            .setData(data, merge: true)
    }
    
    private func createQueryAssociation(from originalQuery: String, to suggestion: String) {
        let data: [String: Any] = [
            "originalQuery": originalQuery,
            "selectedSuggestion": suggestion,
            "timestamp": Date(),
            "count": FieldValue.increment(Int64(1))
        ]
        
        let associationId = "\(originalQuery)_to_\(suggestion)".replacingOccurrences(of: " ", with: "_")
        
        db.collection("analytics")
            .document("suggestions")
            .collection("associations")
            .document(associationId)
            .setData(data, merge: true)
    }
    
    // MARK: - Auto-complete
    func getAutoCompleteOptions(for partialQuery: String) -> [String] {
        let query = partialQuery.lowercased()
        
        var autoComplete: [String] = []
        
        // Find terms that start with the partial query
        autoComplete.append(contentsOf: commonSearchTerms.filter { term in
            term.lowercased().hasPrefix(query) && term.lowercased() != query
        })
        
        // Find patterns that contain the partial query
        autoComplete.append(contentsOf: searchPatterns.filter { pattern in
            pattern.lowercased().contains(query)
        })
        
        return Array(OrderedSet(autoComplete)).prefix(5).map { String($0) }
    }
    
    // MARK: - Smart Suggestions
    func getSmartSuggestions(basedOn userHistory: [String], currentContext: [String: Any] = [:]) -> [String] {
        var suggestions: [String] = []
        
        // Analyze user's search patterns
        let userTerms = userHistory.flatMap { query in
            query.lowercased().components(separatedBy: .whitespacesAndPunctuation)
        }
        
        let termFrequency = Dictionary(grouping: userTerms, by: { $0 }).mapValues { $0.count }
        let popularUserTerms = termFrequency.sorted { $0.value > $1.value }.prefix(5).map { $0.key }
        
        // Generate suggestions based on user preferences
        for term in popularUserTerms {
            suggestions.append(contentsOf: getRelatedTerms(for: term))
        }
        
        // Add contextual suggestions if available
        if let currentCategory = currentContext["category"] as? String {
            suggestions.append(contentsOf: getCategorySuggestions(for: currentCategory))
        }
        
        return Array(OrderedSet(suggestions)).prefix(maxSuggestions).map { String($0) }
    }
    
    private func getRelatedTerms(for term: String) -> [String] {
        let relationshipMap: [String: [String]] = [
            "birthday": ["birthday wishes", "birthday party", "celebration"],
            "thank": ["thank you", "gratitude", "appreciation"],
            "love": ["love message", "romantic", "valentine"],
            "congratulations": ["achievement", "success", "graduation"],
            "holiday": ["christmas", "new year", "thanksgiving"],
            "wedding": ["marriage", "anniversary", "celebration"],
            "baby": ["newborn", "birth announcement", "congratulations"]
        ]
        
        return relationshipMap[term] ?? []
    }
    
    private func getCategorySuggestions(for category: String) -> [String] {
        let categoryMap: [String: [String]] = [
            "celebrations": ["birthday", "anniversary", "graduation", "wedding"],
            "gratitude": ["thank you", "appreciation", "recognition"],
            "sympathy": ["condolences", "sympathy", "support"],
            "love": ["romantic", "valentine", "love message"],
            "holiday": ["christmas", "new year", "thanksgiving", "holiday greetings"]
        ]
        
        return categoryMap[category.lowercased()] ?? []
    }
    
    // MARK: - Utility Functions
    private func levenshteinDistance(_ lhs: String, _ rhs: String) -> Int {
        let lhsCount = lhs.count
        let rhsCount = rhs.count
        
        if lhsCount == 0 { return rhsCount }
        if rhsCount == 0 { return lhsCount }
        
        var matrix = Array(repeating: Array(repeating: 0, count: rhsCount + 1), count: lhsCount + 1)
        
        for i in 0...lhsCount { matrix[i][0] = i }
        for j in 0...rhsCount { matrix[0][j] = j }
        
        for i in 1...lhsCount {
            for j in 1...rhsCount {
                let cost = lhs[lhs.index(lhs.startIndex, offsetBy: i-1)] == rhs[rhs.index(rhs.startIndex, offsetBy: j-1)] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i-1][j] + 1,      // deletion
                    matrix[i][j-1] + 1,      // insertion
                    matrix[i-1][j-1] + cost  // substitution
                )
            }
        }
        
        return matrix[lhsCount][rhsCount]
    }
    
    // MARK: - Cache Management
    func clearSuggestionCache() {
        suggestionCache.removeAll()
    }
    
    func preloadPopularSuggestions() {
        Task {
            do {
                let snapshot = try await db.collection("analytics")
                    .document("suggestions")
                    .collection("weights")
                    .order(by: "weight", descending: true)
                    .limit(to: 20)
                    .getDocuments()
                
                let popularSuggestions = snapshot.documents.compactMap { document in
                    document.data()["suggestion"] as? String
                }
                
                // Cache popular suggestions
                DispatchQueue.main.async {
                    for suggestion in popularSuggestions {
                        self.suggestionCache[suggestion] = [suggestion]
                    }
                }
                
            } catch {
                print("Error preloading popular suggestions: \(error)")
            }
        }
    }
}

// MARK: - OrderedSet Helper
struct OrderedSet<T: Hashable> {
    private var set = Set<T>()
    private var array = [T]()
    
    init<S: Sequence>(_ sequence: S) where S.Element == T {
        for element in sequence {
            append(element)
        }
    }
    
    mutating func append(_ element: T) {
        if set.insert(element).inserted {
            array.append(element)
        }
    }
    
    func prefix(_ maxLength: Int) -> ArraySlice<T> {
        return array.prefix(maxLength)
    }
}

extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        return Array(OrderedSet(self).array)
    }
}