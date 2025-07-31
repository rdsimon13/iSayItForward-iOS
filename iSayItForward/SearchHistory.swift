import Foundation
import FirebaseFirestore

// MARK: - Search History Entry
struct SearchHistoryEntry: Identifiable, Codable, Hashable {
    let id: String
    let query: String
    let timestamp: Date
    let resultCount: Int
    let filters: SearchFilter?
    let userUid: String
    
    init(query: String, resultCount: Int, filters: SearchFilter?, userUid: String) {
        self.id = UUID().uuidString
        self.query = query
        self.timestamp = Date()
        self.resultCount = resultCount
        self.filters = filters
        self.userUid = userUid
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: SearchHistoryEntry, rhs: SearchHistoryEntry) -> Bool {
        lhs.id == rhs.id
    }
    
    // Display helpers
    var formattedTimestamp: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
    
    var hasFilters: Bool {
        filters?.hasActiveFilters ?? false
    }
}

// MARK: - Search History Manager
class SearchHistory: ObservableObject {
    @Published var entries: [SearchHistoryEntry] = []
    @Published var isLoading = false
    
    private let db = Firestore.firestore()
    private let maxHistoryEntries = 50
    private let maxRecentSearches = 10
    
    // MARK: - Recent Searches
    var recentSearches: [String] {
        Array(Set(entries.prefix(maxRecentSearches).map(\.query)))
    }
    
    var popularSearches: [String] {
        let queryCount = Dictionary(grouping: entries, by: \.query)
            .mapValues { $0.count }
        
        return queryCount.sorted { $0.value > $1.value }
            .prefix(5)
            .map(\.key)
    }
    
    // MARK: - Add Entry
    func addEntry(query: String, resultCount: Int, filters: SearchFilter?, userUid: String) {
        let entry = SearchHistoryEntry(
            query: query,
            resultCount: resultCount,
            filters: filters,
            userUid: userUid
        )
        
        // Add to local array
        entries.insert(entry, at: 0)
        
        // Keep only the latest entries
        if entries.count > maxHistoryEntries {
            entries = Array(entries.prefix(maxHistoryEntries))
        }
        
        // Save to Firestore
        saveEntryToFirestore(entry)
    }
    
    // MARK: - Load History
    func loadHistory(for userUid: String) {
        isLoading = true
        
        db.collection("users")
            .document(userUid)
            .collection("searchHistory")
            .order(by: "timestamp", descending: true)
            .limit(to: maxHistoryEntries)
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        print("Error loading search history: \(error)")
                        return
                    }
                    
                    guard let documents = snapshot?.documents else { return }
                    
                    self?.entries = documents.compactMap { document in
                        try? document.data(as: SearchHistoryEntry.self)
                    }
                }
            }
    }
    
    // MARK: - Clear History
    func clearHistory(for userUid: String) {
        entries.removeAll()
        
        // Clear from Firestore
        db.collection("users")
            .document(userUid)
            .collection("searchHistory")
            .getDocuments { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                for document in documents {
                    self?.db.collection("users")
                        .document(userUid)
                        .collection("searchHistory")
                        .document(document.documentID)
                        .delete()
                }
            }
    }
    
    // MARK: - Remove Entry
    func removeEntry(_ entry: SearchHistoryEntry, for userUid: String) {
        entries.removeAll { $0.id == entry.id }
        
        // Remove from Firestore
        db.collection("users")
            .document(userUid)
            .collection("searchHistory")
            .document(entry.id)
            .delete()
    }
    
    // MARK: - Search History
    func searchHistory(query: String) -> [SearchHistoryEntry] {
        guard !query.isEmpty else { return entries }
        
        let lowercasedQuery = query.lowercased()
        return entries.filter { entry in
            entry.query.lowercased().contains(lowercasedQuery)
        }
    }
    
    // MARK: - Get Suggestions
    func getSuggestions(for partialQuery: String) -> [String] {
        guard partialQuery.count >= 2 else { return recentSearches }
        
        let lowercasedQuery = partialQuery.lowercased()
        let matchingQueries = entries.compactMap { entry -> String? in
            let query = entry.query
            if query.lowercased().hasPrefix(lowercasedQuery) {
                return query
            }
            return nil
        }
        
        // Remove duplicates and limit results
        return Array(Set(matchingQueries)).prefix(5).map { $0 }
    }
    
    // MARK: - Analytics
    var searchFrequency: [String: Int] {
        Dictionary(grouping: entries, by: \.query).mapValues { $0.count }
    }
    
    var averageResultCount: Double {
        guard !entries.isEmpty else { return 0 }
        let total = entries.reduce(0) { $0 + $1.resultCount }
        return Double(total) / Double(entries.count)
    }
    
    var searchesByDay: [Date: Int] {
        let calendar = Calendar.current
        let groupedByDay = Dictionary(grouping: entries) { entry in
            calendar.startOfDay(for: entry.timestamp)
        }
        return groupedByDay.mapValues { $0.count }
    }
    
    // MARK: - Private Methods
    private func saveEntryToFirestore(_ entry: SearchHistoryEntry) {
        do {
            try db.collection("users")
                .document(entry.userUid)
                .collection("searchHistory")
                .document(entry.id)
                .setData(from: entry)
        } catch {
            print("Error saving search history entry: \(error)")
        }
    }
}

// MARK: - Search History Extensions
extension SearchHistory {
    
    // Get entries for a specific time period
    func entries(for period: SearchHistoryPeriod) -> [SearchHistoryEntry] {
        let now = Date()
        let calendar = Calendar.current
        
        let startDate: Date
        switch period {
        case .today:
            startDate = calendar.startOfDay(for: now)
        case .week:
            startDate = calendar.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .all:
            return entries
        }
        
        return entries.filter { $0.timestamp >= startDate }
    }
    
    // Get most searched terms for a period
    func topSearchTerms(for period: SearchHistoryPeriod, limit: Int = 5) -> [(term: String, count: Int)] {
        let periodEntries = entries(for: period)
        let termCounts = Dictionary(grouping: periodEntries, by: \.query)
            .mapValues { $0.count }
        
        return termCounts.sorted { $0.value > $1.value }
            .prefix(limit)
            .map { (term: $0.key, count: $0.value) }
    }
}

// MARK: - Search History Period
enum SearchHistoryPeriod: String, CaseIterable {
    case today = "today"
    case week = "week"
    case month = "month"
    case all = "all"
    
    var displayName: String {
        switch self {
        case .today: return "Today"
        case .week: return "This Week"
        case .month: return "This Month"
        case .all: return "All Time"
        }
    }
}