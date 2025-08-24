import Foundation
import FirebaseFirestore
import Combine

class CategoryService: ObservableObject {
    
    // MARK: - Properties
    @Published var categories: [Category] = []
    @Published var tags: [Tag] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private let suggestionEngine = TagSuggestionEngine()
    private var cancellables = Set<AnyCancellable>()
    
    // Cache
    private var categoriesCache: [Category] = []
    private var tagsCache: [Tag] = []
    private var lastCacheUpdate: Date?
    
    // MARK: - Initialization
    init() {
        setupSystemCategories()
        loadCachedData()
    }
    
    // MARK: - Category Management
    func fetchCategories() async {
        await MainActor.run { isLoading = true }
        
        do {
            let snapshot = try await db.collection(CategoryConstants.categoriesCollection)
                .whereField("isActive", isEqualTo: true)
                .order(by: "sortOrder")
                .getDocuments()
            
            let fetchedCategories = try snapshot.documents.compactMap { document in
                try document.data(as: Category.self)
            }
            
            await MainActor.run {
                self.categories = fetchedCategories
                self.categoriesCache = fetchedCategories
                self.lastCacheUpdate = Date()
                self.isLoading = false
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func createCategory(_ category: Category) async -> Bool {
        do {
            try await db.collection(CategoryConstants.categoriesCollection)
                .addDocument(from: category)
            
            await MainActor.run {
                self.categories.append(category)
            }
            
            return true
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            return false
        }
    }
    
    func updateCategory(_ category: Category) async -> Bool {
        guard let categoryId = category.id else { return false }
        
        do {
            try await db.collection(CategoryConstants.categoriesCollection)
                .document(categoryId)
                .setData(from: category)
            
            await MainActor.run {
                if let index = self.categories.firstIndex(where: { $0.id == categoryId }) {
                    self.categories[index] = category
                }
            }
            
            return true
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            return false
        }
    }
    
    func deleteCategory(_ categoryId: String) async -> Bool {
        do {
            await db.collection(CategoryConstants.categoriesCollection)
                .document(categoryId)
                .updateData(["isActive": false])
            
            await MainActor.run {
                self.categories.removeAll { $0.id == categoryId }
            }
            
            return true
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            return false
        }
    }
    
    // MARK: - Tag Management
    func fetchTags() async {
        do {
            let snapshot = try await db.collection(CategoryConstants.tagsCollection)
                .whereField("isBlocked", isEqualTo: false)
                .order(by: "usageCount", descending: true)
                .getDocuments()
            
            let fetchedTags = try snapshot.documents.compactMap { document in
                try document.data(as: Tag.self)
            }
            
            await MainActor.run {
                self.tags = fetchedTags
                self.tagsCache = fetchedTags
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func createOrUpdateTag(_ tagName: String, createdBy: String?) async -> Tag? {
        let normalizedName = Tag.normalize(tagName)
        
        // Check if tag already exists
        if let existingTag = await findTag(by: normalizedName) {
            // Update usage count
            var updatedTag = existingTag
            updatedTag.usageCount += 1
            updatedTag.lastUsedDate = Date()
            
            if await updateTag(updatedTag) {
                return updatedTag
            }
        } else {
            // Create new tag
            let newTag = Tag(name: tagName, createdBy: createdBy)
            if await createTag(newTag) {
                return newTag
            }
        }
        
        return nil
    }
    
    private func createTag(_ tag: Tag) async -> Bool {
        do {
            try await db.collection(CategoryConstants.tagsCollection)
                .addDocument(from: tag)
            
            await MainActor.run {
                self.tags.append(tag)
            }
            
            return true
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            return false
        }
    }
    
    private func updateTag(_ tag: Tag) async -> Bool {
        guard let tagId = tag.id else { return false }
        
        do {
            try await db.collection(CategoryConstants.tagsCollection)
                .document(tagId)
                .setData(from: tag)
            
            await MainActor.run {
                if let index = self.tags.firstIndex(where: { $0.id == tagId }) {
                    self.tags[index] = tag
                }
            }
            
            return true
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            return false
        }
    }
    
    private func findTag(by normalizedName: String) async -> Tag? {
        do {
            let snapshot = try await db.collection(CategoryConstants.tagsCollection)
                .whereField("normalizedName", isEqualTo: normalizedName)
                .limit(to: 1)
                .getDocuments()
            
            return try snapshot.documents.first?.data(as: Tag.self)
        } catch {
            return nil
        }
    }
    
    // MARK: - Tag Suggestions
    func generateTagSuggestions(
        for content: String,
        category: Category? = nil,
        userHistory: [String] = [],
        existingTags: [String] = []
    ) async -> [TagSuggestion] {
        
        return await suggestionEngine.generateSuggestions(
            for: content,
            category: category,
            userHistory: userHistory,
            existingTags: existingTags
        )
    }
    
    // MARK: - Search and Filtering
    func searchCategories(_ searchText: String) -> [Category] {
        guard !searchText.isEmpty else { return categories }
        
        let lowercased = searchText.lowercased()
        return categories.filter { category in
            category.name.lowercased().contains(lowercased) ||
            category.description.lowercased().contains(lowercased)
        }
    }
    
    func searchTags(_ searchText: String) -> [Tag] {
        guard !searchText.isEmpty else { return tags }
        
        let lowercased = searchText.lowercased()
        return tags.filter { tag in
            tag.name.lowercased().contains(lowercased) ||
            tag.normalizedName.contains(lowercased)
        }
    }
    
    func getPopularTags(limit: Int = 20) -> [Tag] {
        return Array(tags.sorted { $0.usageCount > $1.usageCount }.prefix(limit))
    }
    
    func getTrendingTags(limit: Int = 10) -> [Tag] {
        return Array(tags.sorted { $0.trendingScore > $1.trendingScore }.prefix(limit))
    }
    
    // MARK: - Category Subscriptions
    func subscribeToCategory(_ categoryId: String, userId: String) async -> Bool {
        let subscription = CategorySubscription(userId: userId, categoryId: categoryId)
        
        do {
            try await db.collection(CategoryConstants.categorySubscriptionsCollection)
                .addDocument(from: subscription)
            return true
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            return false
        }
    }
    
    func unsubscribeFromCategory(_ categoryId: String, userId: String) async -> Bool {
        do {
            let snapshot = try await db.collection(CategoryConstants.categorySubscriptionsCollection)
                .whereField("userId", isEqualTo: userId)
                .whereField("categoryId", isEqualTo: categoryId)
                .getDocuments()
            
            for document in snapshot.documents {
                try await document.reference.delete()
            }
            
            return true
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            return false
        }
    }
    
    func getUserSubscriptions(_ userId: String) async -> [CategorySubscription] {
        do {
            let snapshot = try await db.collection(CategoryConstants.categorySubscriptionsCollection)
                .whereField("userId", isEqualTo: userId)
                .whereField("isActive", isEqualTo: true)
                .getDocuments()
            
            return try snapshot.documents.compactMap { document in
                try document.data(as: CategorySubscription.self)
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            return []
        }
    }
    
    // MARK: - Statistics
    func updateCategoryStats(_ categoryId: String, userId: String?, action: StatsAction) async {
        // Implementation for updating category statistics
        // This would typically update counters in the CategoryStats collection
    }
    
    func getCategoryStats(_ categoryId: String, period: StatsPeriod) async -> CategoryStats? {
        do {
            let snapshot = try await db.collection(CategoryConstants.categoryStatsCollection)
                .whereField("categoryId", isEqualTo: categoryId)
                .whereField("period", isEqualTo: period.rawValue)
                .limit(to: 1)
                .getDocuments()
            
            return try snapshot.documents.first?.data(as: CategoryStats.self)
        } catch {
            return nil
        }
    }
    
    // MARK: - Private Methods
    private func setupSystemCategories() {
        Task {
            // Check if system categories exist, if not create them
            let existingCategories = await fetchSystemCategories()
            let systemCategories = Category.systemCategories
            
            for systemCategory in systemCategories {
                let exists = existingCategories.contains { $0.name == systemCategory.name }
                if !exists {
                    _ = await createCategory(systemCategory)
                }
            }
        }
    }
    
    private func fetchSystemCategories() async -> [Category] {
        do {
            let snapshot = try await db.collection(CategoryConstants.categoriesCollection)
                .whereField("isSystem", isEqualTo: true)
                .getDocuments()
            
            return try snapshot.documents.compactMap { document in
                try document.data(as: Category.self)
            }
        } catch {
            return []
        }
    }
    
    private func loadCachedData() {
        // Load from cache if available and recent
        if let lastUpdate = lastCacheUpdate,
           Date().timeIntervalSince(lastUpdate) < CategoryConstants.categoryListCacheTimeout {
            self.categories = categoriesCache
            self.tags = tagsCache
        } else {
            Task {
                await fetchCategories()
                await fetchTags()
            }
        }
    }
}

// MARK: - Supporting Types
enum StatsAction {
    case view
    case like
    case share
    case message
}

// MARK: - CategoryService Extensions
extension CategoryService {
    func getCategoriesForUser(_ userId: String) async -> [Category] {
        let subscriptions = await getUserSubscriptions(userId)
        let subscribedCategoryIds = Set(subscriptions.map { $0.categoryId })
        
        return categories.filter { category in
            guard let categoryId = category.id else { return false }
            return subscribedCategoryIds.contains(categoryId) || category.isSystem
        }
    }
    
    func getRecommendedCategories(for userId: String) async -> [Category] {
        // This would implement a recommendation algorithm
        // For now, return popular categories
        return categories.sorted { $0.messageCount > $1.messageCount }
    }
}