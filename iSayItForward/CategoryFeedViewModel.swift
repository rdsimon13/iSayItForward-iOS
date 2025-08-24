import Foundation
import SwiftUI
import Combine
import FirebaseFirestore

@MainActor
class CategoryFeedViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var selectedCategory: Category?
    @Published var messages: [SIFItem] = []
    @Published var filteredMessages: [SIFItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentFilter: FeedFilter = .all
    @Published var sortOption: FeedSortOption = .newest
    @Published var searchText = ""
    
    // MARK: - Private Properties
    private let categoryService = CategoryService()
    private var cancellables = Set<AnyCancellable>()
    private let db = Firestore.firestore()
    
    // MARK: - Computed Properties
    var hasMessages: Bool {
        !messages.isEmpty
    }
    
    var messageCount: Int {
        filteredMessages.count
    }
    
    var categoryTitle: String {
        selectedCategory?.displayName ?? "All Categories"
    }
    
    var categoryDescription: String {
        selectedCategory?.description ?? "Messages from all categories"
    }
    
    // MARK: - Initialization
    init() {
        setupBindings()
    }
    
    // MARK: - Public Methods
    func selectCategory(_ category: Category?) {
        selectedCategory = category
        loadMessages()
        
        // Update category view statistics
        if let category = category, let categoryId = category.id {
            Task {
                await categoryService.updateCategoryStats(categoryId, userId: getCurrentUserId(), action: .view)
            }
        }
    }
    
    func loadMessages() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let fetchedMessages = await fetchMessagesForCategory()
                
                await MainActor.run {
                    self.messages = fetchedMessages
                    self.updateFilteredMessages()
                    self.isLoading = false
                }
                
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    func refreshMessages() {
        loadMessages()
    }
    
    func setFilter(_ filter: FeedFilter) {
        currentFilter = filter
        updateFilteredMessages()
    }
    
    func setSortOption(_ option: FeedSortOption) {
        sortOption = option
        updateFilteredMessages()
    }
    
    func searchMessages(_ query: String) {
        searchText = query
        updateFilteredMessages()
    }
    
    func clearSearch() {
        searchText = ""
        updateFilteredMessages()
    }
    
    func getMessagesWithTag(_ tagName: String) -> [SIFItem] {
        return messages.filter { message in
            message.tags.contains { $0.lowercased() == tagName.lowercased() }
        }
    }
    
    func getRelatedCategories() -> [Category] {
        guard let selectedCategory = selectedCategory else { return [] }
        
        // Get categories that share tags with current category
        let categoryMessages = messages.filter { message in
            message.categoryIds.contains(selectedCategory.id ?? "")
        }
        
        let commonTags = Set(categoryMessages.flatMap { $0.tags })
        
        // Find other categories with similar tags
        return categoryService.categories.filter { category in
            guard category.id != selectedCategory.id else { return false }
            
            let categoryMessagesWithTags = messages.filter { message in
                message.categoryIds.contains(category.id ?? "") &&
                !Set(message.tags).isDisjoint(with: commonTags)
            }
            
            return !categoryMessagesWithTags.isEmpty
        }
    }
    
    func getPopularTags() -> [String] {
        let allTags = messages.flatMap { $0.tags }
        let tagCounts = Dictionary(allTags.map { ($0, 1) }, uniquingKeysWith: +)
        
        return tagCounts.sorted { $0.value > $1.value }
            .prefix(10)
            .map { $0.key }
    }
    
    func shareMessage(_ message: SIFItem) {
        // Update share statistics
        if let firstCategoryId = message.categoryIds.first {
            Task {
                await categoryService.updateCategoryStats(firstCategoryId, userId: getCurrentUserId(), action: .share)
            }
        }
    }
    
    func likeMessage(_ message: SIFItem) {
        // Update like statistics
        if let firstCategoryId = message.categoryIds.first {
            Task {
                await categoryService.updateCategoryStats(firstCategoryId, userId: getCurrentUserId(), action: .like)
            }
        }
    }
    
    // MARK: - Private Methods
    private func setupBindings() {
        // Update filtered messages when search text, filter, or sort option changes
        Publishers.CombineLatest3($searchText, $currentFilter, $sortOption)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _, _, _ in
                self?.updateFilteredMessages()
            }
            .store(in: &cancellables)
    }
    
    private func fetchMessagesForCategory() async -> [SIFItem] {
        do {
            var query = db.collection(CategoryConstants.sifsCollection)
                .order(by: "createdDate", descending: true)
            
            // Filter by category if one is selected
            if let selectedCategory = selectedCategory,
               let categoryId = selectedCategory.id {
                query = query.whereField("categoryIds", arrayContains: categoryId)
            }
            
            let snapshot = try await query.getDocuments()
            
            return try snapshot.documents.compactMap { document in
                try document.data(as: SIFItem.self)
            }
            
        } catch {
            throw error
        }
    }
    
    private func updateFilteredMessages() {
        var filtered = messages
        
        // Apply search filter
        if !searchText.isEmpty {
            let lowercased = searchText.lowercased()
            filtered = filtered.filter { message in
                message.subject.lowercased().contains(lowercased) ||
                message.message.lowercased().contains(lowercased) ||
                message.tags.contains { $0.lowercased().contains(lowercased) }
            }
        }
        
        // Apply category filter
        switch currentFilter {
        case .all:
            break
        case .recent:
            let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            filtered = filtered.filter { $0.createdDate >= oneWeekAgo }
        case .popular:
            // This would typically be based on engagement metrics
            // For now, use message count as a proxy
            break
        case .withTags:
            filtered = filtered.filter { !$0.tags.isEmpty }
        }
        
        // Apply sort
        switch sortOption {
        case .newest:
            filtered.sort { $0.createdDate > $1.createdDate }
        case .oldest:
            filtered.sort { $0.createdDate < $1.createdDate }
        case .subject:
            filtered.sort { $0.subject < $1.subject }
        case .scheduled:
            filtered.sort { $0.scheduledDate > $1.scheduledDate }
        }
        
        filteredMessages = filtered
    }
    
    private func getCurrentUserId() -> String? {
        // This would typically get the current user ID from AuthState or similar
        return "current_user_id" // Placeholder
    }
}

// MARK: - Supporting Types
enum FeedFilter: String, CaseIterable {
    case all = "all"
    case recent = "recent"
    case popular = "popular"
    case withTags = "with_tags"
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .recent: return "Recent"
        case .popular: return "Popular"
        case .withTags: return "Tagged"
        }
    }
    
    var iconName: String {
        switch self {
        case .all: return "list.bullet"
        case .recent: return "clock.fill"
        case .popular: return "flame.fill"
        case .withTags: return "tag.fill"
        }
    }
}

enum FeedSortOption: String, CaseIterable {
    case newest = "newest"
    case oldest = "oldest"
    case subject = "subject"
    case scheduled = "scheduled"
    
    var displayName: String {
        switch self {
        case .newest: return "Newest First"
        case .oldest: return "Oldest First"
        case .subject: return "By Subject"
        case .scheduled: return "By Schedule"
        }
    }
    
    var iconName: String {
        switch self {
        case .newest: return "arrow.down"
        case .oldest: return "arrow.up"
        case .subject: return "textformat.abc"
        case .scheduled: return "calendar"
        }
    }
}

// MARK: - CategoryFeedViewModel Extensions
extension CategoryFeedViewModel {
    func getMessagesByTimeframe(_ timeframe: TimeInterval) -> [SIFItem] {
        let cutoffDate = Date().addingTimeInterval(-timeframe)
        return messages.filter { $0.createdDate >= cutoffDate }
    }
    
    func getMessagesForToday() -> [SIFItem] {
        let calendar = Calendar.current
        return messages.filter { calendar.isDateInToday($0.createdDate) }
    }
    
    func getMessagesForThisWeek() -> [SIFItem] {
        return getMessagesByTimeframe(7 * 24 * 60 * 60) // 1 week in seconds
    }
    
    func getMessagesForThisMonth() -> [SIFItem] {
        return getMessagesByTimeframe(30 * 24 * 60 * 60) // 30 days in seconds
    }
    
    func getTagCloud() -> [String: Int] {
        let allTags = messages.flatMap { $0.tags }
        return Dictionary(allTags.map { ($0, 1) }, uniquingKeysWith: +)
    }
}