import Foundation
import FirebaseFirestore
import FirebaseAuth

// MARK: - Search Analytics
class SearchAnalytics: ObservableObject {
    private let db = Firestore.firestore()
    
    // MARK: - Analytics Events
    func trackSearchStarted(query: String, filters: SearchFilter) {
        logEvent("search_started", parameters: [
            "query": query,
            "has_filters": filters.hasActiveFilters,
            "filter_types": filters.resultTypes.map(\.rawValue).joined(separator: ","),
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    func trackSearchCompleted(query: String, resultCount: Int, filters: SearchFilter) {
        logEvent("search_completed", parameters: [
            "query": query,
            "result_count": resultCount,
            "has_filters": filters.hasActiveFilters,
            "filter_count": filters.activeFilterCount,
            "sort_by": filters.sortBy.rawValue,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    func trackSearchFailed(query: String, error: Error) {
        logEvent("search_failed", parameters: [
            "query": query,
            "error": error.localizedDescription,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    func trackSearchQuery(query: String, resultCount: Int, filters: SearchFilter) {
        guard let userUid = Auth.auth().currentUser?.uid else { return }
        
        let searchMetrics = SearchMetrics(
            userUid: userUid,
            query: query,
            resultCount: resultCount,
            hasFilters: filters.hasActiveFilters,
            filterCount: filters.activeFilterCount,
            sortBy: filters.sortBy.rawValue,
            timestamp: Date()
        )
        
        saveSearchMetrics(searchMetrics)
    }
    
    func trackResultSelected(result: SearchResult, position: Int) {
        logEvent("result_selected", parameters: [
            "result_type": result.type.rawValue,
            "result_id": result.id,
            "position": position,
            "score": result.score,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    func trackFilterApplied(filter: SearchFilter) {
        logEvent("filter_applied", parameters: [
            "filter_types": filter.resultTypes.map(\.rawValue).joined(separator: ","),
            "has_date_filter": filter.dateRange.isActive,
            "has_category_filter": !filter.categories.isEmpty,
            "has_author_filter": !filter.authorUids.isEmpty,
            "sort_by": filter.sortBy.rawValue,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    func trackSuggestionSelected(suggestion: String, query: String) {
        logEvent("suggestion_selected", parameters: [
            "suggestion": suggestion,
            "original_query": query,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    func trackInteraction(_ interaction: String, context: [String: String] = [:]) {
        var parameters = context
        parameters["interaction"] = interaction
        parameters["timestamp"] = String(Date().timeIntervalSince1970)
        
        logEvent("search_interaction", parameters: parameters)
    }
    
    // MARK: - Metrics Collection
    func getSearchMetrics(for userUid: String, completion: @escaping (SearchAnalyticsReport?) -> Void) {
        db.collection("analytics")
            .document("searches")
            .collection("user_metrics")
            .document(userUid)
            .collection("searches")
            .order(by: "timestamp", descending: true)
            .limit(to: 100)
            .getDocuments { snapshot, error in
                guard let documents = snapshot?.documents else {
                    completion(nil)
                    return
                }
                
                let metrics = documents.compactMap { document -> SearchMetrics? in
                    try? document.data(as: SearchMetrics.self)
                }
                
                let report = self.generateAnalyticsReport(from: metrics)
                completion(report)
            }
    }
    
    func getGlobalSearchTrends(completion: @escaping ([SearchTrend]) -> Void) {
        db.collection("analytics")
            .document("searches")
            .collection("trends")
            .order(by: "timestamp", descending: true)
            .limit(to: 20)
            .getDocuments { snapshot, error in
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                
                let trends = documents.compactMap { document -> SearchTrend? in
                    try? document.data(as: SearchTrend.self)
                }
                
                completion(trends)
            }
    }
    
    // MARK: - Private Methods
    private func logEvent(_ eventName: String, parameters: [String: Any]) {
        // Log to console for debugging
        print("Analytics Event: \(eventName)")
        print("Parameters: \(parameters)")
        
        // In a real app, you might also send to Firebase Analytics or other services
        // Analytics.logEvent(eventName, parameters: parameters)
    }
    
    private func saveSearchMetrics(_ metrics: SearchMetrics) {
        do {
            try db.collection("analytics")
                .document("searches")
                .collection("user_metrics")
                .document(metrics.userUid)
                .collection("searches")
                .document(metrics.id)
                .setData(from: metrics)
        } catch {
            print("Error saving search metrics: \(error)")
        }
    }
    
    private func generateAnalyticsReport(from metrics: [SearchMetrics]) -> SearchAnalyticsReport {
        let totalSearches = metrics.count
        let uniqueQueries = Set(metrics.map(\.query)).count
        let averageResults = metrics.isEmpty ? 0 : metrics.reduce(0) { $0 + $1.resultCount } / totalSearches
        
        let topQueries = Dictionary(grouping: metrics, by: \.query)
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
            .prefix(10)
            .map { QueryFrequency(query: $0.key, count: $0.value) }
        
        let searchesByDay = Dictionary(grouping: metrics) { metric in
            Calendar.current.startOfDay(for: metric.timestamp)
        }.mapValues { $0.count }
        
        return SearchAnalyticsReport(
            totalSearches: totalSearches,
            uniqueQueries: uniqueQueries,
            averageResults: averageResults,
            topQueries: topQueries,
            searchesByDay: searchesByDay,
            generatedAt: Date()
        )
    }
}

// MARK: - Search Metrics Model
struct SearchMetrics: Identifiable, Codable {
    let id: String
    let userUid: String
    let query: String
    let resultCount: Int
    let hasFilters: Bool
    let filterCount: Int
    let sortBy: String
    let timestamp: Date
    
    init(userUid: String, query: String, resultCount: Int, hasFilters: Bool, filterCount: Int, sortBy: String, timestamp: Date) {
        self.id = UUID().uuidString
        self.userUid = userUid
        self.query = query
        self.resultCount = resultCount
        self.hasFilters = hasFilters
        self.filterCount = filterCount
        self.sortBy = sortBy
        self.timestamp = timestamp
    }
}

// MARK: - Search Trend Model
struct SearchTrend: Identifiable, Codable {
    let id: String
    let query: String
    let searchCount: Int
    let trendScore: Double
    let timeframe: String
    let timestamp: Date
}

// MARK: - Analytics Report Models
struct SearchAnalyticsReport {
    let totalSearches: Int
    let uniqueQueries: Int
    let averageResults: Int
    let topQueries: [QueryFrequency]
    let searchesByDay: [Date: Int]
    let generatedAt: Date
}

struct QueryFrequency {
    let query: String
    let count: Int
    
    var percentage: Double {
        // This would need to be calculated relative to total searches
        return 0.0
    }
}