import Foundation
import Combine
import FirebaseAuth

// MARK: - Search View Model
class SearchViewModel: ObservableObject {
    @Published var searchQuery = ""
    @Published var searchResults: [SearchResult] = []
    @Published var filteredResults: [SearchResult] = []
    @Published var isSearching = false
    @Published var hasSearched = false
    @Published var currentFilter = SearchFilter()
    @Published var suggestions: [String] = []
    @Published var showingSuggestions = false
    @Published var errorMessage: String?
    
    // Pagination
    @Published var currentPage = 0
    @Published var hasMoreResults = false
    private let pageSize = 20
    
    // Search state
    @Published var searchHistory = SearchHistory()
    @Published var recentSearches: [String] = []
    @Published var isShowingFilters = false
    @Published var isShowingHistory = false
    
    // Services
    private let searchService = SearchService()
    private let analytics = SearchAnalytics()
    private var cancellables = Set<AnyCancellable>()
    
    // Debounce timer for search suggestions
    private var suggestionTimer: Timer?
    
    init() {
        setupBindings()
        loadSearchHistory()
    }
    
    // MARK: - Setup
    private func setupBindings() {
        // Debounced search query for suggestions
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                self?.handleQueryChange(query)
            }
            .store(in: &cancellables)
        
        // Monitor search service
        searchService.$isSearching
            .assign(to: \.isSearching, on: self)
            .store(in: &cancellables)
        
        searchService.$searchResults
            .sink { [weak self] results in
                self?.handleSearchResults(results)
            }
            .store(in: &cancellables)
        
        searchService.$suggestions
            .assign(to: \.suggestions, on: self)
            .store(in: &cancellables)
        
        searchService.$errorMessage
            .assign(to: \.errorMessage, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Search Methods
    func performSearch() {
        guard !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            clearResults()
            return
        }
        
        hasSearched = true
        currentPage = 0
        showingSuggestions = false
        
        searchService.search(query: searchQuery, filters: currentFilter) { [weak self] results in
            DispatchQueue.main.async {
                self?.addSearchToHistory()
            }
        }
    }
    
    func searchWithSuggestion(_ suggestion: String) {
        searchQuery = suggestion
        performSearch()
    }
    
    func searchFromHistory(_ historyEntry: SearchHistoryEntry) {
        searchQuery = historyEntry.query
        if let filters = historyEntry.filters {
            currentFilter = filters
        }
        performSearch()
    }
    
    // MARK: - Query Handling
    private func handleQueryChange(_ query: String) {
        if query.isEmpty {
            clearSuggestions()
            if hasSearched {
                clearResults()
            }
            return
        }
        
        // Show suggestions for queries with 2+ characters
        if query.count >= 2 && !hasSearched {
            showingSuggestions = true
            loadSuggestions(for: query)
        } else {
            showingSuggestions = false
        }
        
        // Auto-search if filter is applied and query changes
        if hasSearched && currentFilter.hasActiveFilters {
            performSearch()
        }
    }
    
    private func loadSuggestions(for query: String) {
        // Get suggestions from search history first
        let historySuggestions = searchHistory.getSuggestions(for: query)
        
        // Get suggestions from search service
        searchService.getSuggestions(for: query) { [weak self] serviceSuggestions in
            DispatchQueue.main.async {
                // Combine and deduplicate suggestions
                let allSuggestions = Array(Set(historySuggestions + serviceSuggestions))
                self?.suggestions = Array(allSuggestions.prefix(8))
            }
        }
    }
    
    // MARK: - Results Handling
    private func handleSearchResults(_ results: [SearchResult]) {
        searchResults = results
        applyCurrentFilter()
        updatePagination()
    }
    
    private func applyCurrentFilter() {
        if currentFilter.hasActiveFilters {
            filteredResults = searchResults.filter { currentFilter.matches(result: $0) }
        } else {
            filteredResults = searchResults
        }
    }
    
    private func updatePagination() {
        let totalResults = filteredResults.count
        let maxPage = (totalResults + pageSize - 1) / pageSize
        hasMoreResults = currentPage < maxPage - 1
    }
    
    // MARK: - Pagination
    func loadNextPage() {
        guard hasMoreResults else { return }
        currentPage += 1
    }
    
    func loadPreviousPage() {
        guard currentPage > 0 else { return }
        currentPage -= 1
    }
    
    var paginatedResults: [SearchResult] {
        let startIndex = currentPage * pageSize
        let endIndex = min(startIndex + pageSize, filteredResults.count)
        
        guard startIndex < filteredResults.count else { return [] }
        
        return Array(filteredResults[startIndex..<endIndex])
    }
    
    var totalPages: Int {
        return (filteredResults.count + pageSize - 1) / pageSize
    }
    
    var currentPageDisplay: String {
        guard totalPages > 0 else { return "0 of 0" }
        return "\(currentPage + 1) of \(totalPages)"
    }
    
    // MARK: - Filtering
    func applyFilter(_ filter: SearchFilter) {
        currentFilter = filter
        applyCurrentFilter()
        updatePagination()
        currentPage = 0
        
        // Re-search if we have results
        if hasSearched {
            performSearch()
        }
    }
    
    func clearFilters() {
        currentFilter = SearchFilter()
        applyCurrentFilter()
        updatePagination()
        currentPage = 0
    }
    
    func toggleFilter(for resultType: SearchResultType) {
        if currentFilter.resultTypes.contains(resultType) {
            currentFilter.resultTypes.remove(resultType)
        } else {
            currentFilter.resultTypes.insert(resultType)
        }
        applyCurrentFilter()
        updatePagination()
    }
    
    // MARK: - Search History
    private func loadSearchHistory() {
        guard let userUid = Auth.auth().currentUser?.uid else { return }
        searchHistory.loadHistory(for: userUid)
        recentSearches = searchHistory.recentSearches
    }
    
    private func addSearchToHistory() {
        guard let userUid = Auth.auth().currentUser?.uid,
              !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        let filters = currentFilter.hasActiveFilters ? currentFilter : nil
        searchHistory.addEntry(
            query: searchQuery,
            resultCount: filteredResults.count,
            filters: filters,
            userUid: userUid
        )
        
        recentSearches = searchHistory.recentSearches
        
        // Track analytics
        analytics.trackSearchQuery(
            query: searchQuery,
            resultCount: filteredResults.count,
            filters: currentFilter
        )
    }
    
    func clearSearchHistory() {
        guard let userUid = Auth.auth().currentUser?.uid else { return }
        searchHistory.clearHistory(for: userUid)
        recentSearches = []
    }
    
    func removeFromHistory(_ entry: SearchHistoryEntry) {
        guard let userUid = Auth.auth().currentUser?.uid else { return }
        searchHistory.removeEntry(entry, for: userUid)
        recentSearches = searchHistory.recentSearches
    }
    
    // MARK: - UI State Management
    func clearResults() {
        searchResults = []
        filteredResults = []
        hasSearched = false
        currentPage = 0
        hasMoreResults = false
        errorMessage = nil
    }
    
    func clearSuggestions() {
        suggestions = []
        showingSuggestions = false
    }
    
    func clearSearch() {
        searchQuery = ""
        clearResults()
        clearSuggestions()
    }
    
    func showFilters() {
        isShowingFilters = true
    }
    
    func hideFilters() {
        isShowingFilters = false
    }
    
    func showHistory() {
        isShowingHistory = true
    }
    
    func hideHistory() {
        isShowingHistory = false
    }
    
    // MARK: - Result Information
    var hasResults: Bool {
        !filteredResults.isEmpty
    }
    
    var resultsSummary: String {
        let count = filteredResults.count
        if count == 0 {
            return hasSearched ? "No results found" : ""
        } else if count == 1 {
            return "1 result found"
        } else {
            return "\(count) results found"
        }
    }
    
    var isEmpty: Bool {
        searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Quick Actions
    func searchMessages() {
        currentFilter.resultTypes = [.message]
        performSearch()
    }
    
    func searchUsers() {
        currentFilter.resultTypes = [.user]
        performSearch()
    }
    
    func searchTemplates() {
        currentFilter.resultTypes = [.template]
        performSearch()
    }
    
    func searchCategories() {
        currentFilter.resultTypes = [.category]
        performSearch()
    }
    
    // MARK: - Result Actions
    func selectResult(_ result: SearchResult) {
        analytics.trackResultSelected(result: result, position: findResultPosition(result))
    }
    
    private func findResultPosition(_ result: SearchResult) -> Int {
        return paginatedResults.firstIndex(of: result) ?? -1
    }
    
    // MARK: - Sorting
    func sortResults(by option: SearchSortOption, order: SearchSortOrder = .descending) {
        currentFilter.sortBy = option
        currentFilter.sortOrder = order
        
        if hasSearched {
            performSearch()
        }
    }
    
    // MARK: - Analytics
    func trackSearchInteraction(_ interaction: String) {
        analytics.trackInteraction(interaction, context: [
            "query": searchQuery,
            "hasFilters": String(currentFilter.hasActiveFilters),
            "resultCount": String(filteredResults.count)
        ])
    }
}

// MARK: - Search View Model Extensions
extension SearchViewModel {
    
    // Convenient computed properties for UI
    var showEmptyState: Bool {
        hasSearched && !isSearching && filteredResults.isEmpty
    }
    
    var showLoadingState: Bool {
        isSearching && filteredResults.isEmpty
    }
    
    var showResults: Bool {
        hasSearched && !filteredResults.isEmpty
    }
    
    var canLoadNextPage: Bool {
        hasMoreResults && !isSearching
    }
    
    var canLoadPreviousPage: Bool {
        currentPage > 0 && !isSearching
    }
    
    // Filter badge count for UI
    var activeFilterBadgeCount: Int {
        currentFilter.activeFilterCount
    }
    
    // Search suggestions for display
    var displaySuggestions: [String] {
        if searchQuery.isEmpty {
            return recentSearches
        } else {
            return suggestions
        }
    }
}