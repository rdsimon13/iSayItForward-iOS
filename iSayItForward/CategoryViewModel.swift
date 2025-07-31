import Foundation
import SwiftUI
import Combine

@MainActor
class CategoryViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var categories: [Category] = []
    @Published var filteredCategories: [Category] = []
    @Published var selectedCategory: Category?
    @Published var searchText = ""
    @Published var sortOption: CategorySortOption = .name
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingCreateCategory = false
    
    // MARK: - Private Properties
    private let categoryService = CategoryService()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        setupBindings()
        loadCategories()
    }
    
    // MARK: - Public Methods
    func loadCategories() {
        isLoading = true
        
        Task {
            await categoryService.fetchCategories()
            
            self.categories = categoryService.categories
            self.updateFilteredCategories()
            self.isLoading = false
        }
    }
    
    func createCategory(name: String, description: String, iconName: String, colorHex: String, parentCategoryId: String?) {
        guard !name.isEmpty else {
            errorMessage = "Category name cannot be empty"
            return
        }
        
        guard CategoryConstants.validateCategoryName(name) else {
            errorMessage = "Invalid category name"
            return
        }
        
        let newCategory = Category(
            name: name,
            description: description,
            iconName: iconName,
            colorHex: colorHex,
            isSystem: false,
            parentCategoryId: parentCategoryId,
            createdDate: Date(),
            createdBy: getCurrentUserId()
        )
        
        Task {
            let success = await categoryService.createCategory(newCategory)
            if success {
                self.categories.append(newCategory)
                self.updateFilteredCategories()
                self.showingCreateCategory = false
            } else {
                self.errorMessage = "Failed to create category"
            }
        }
    }
    
    func updateCategory(_ category: Category) {
        Task {
            let success = await categoryService.updateCategory(category)
            if success {
                if let index = categories.firstIndex(where: { $0.id == category.id }) {
                    categories[index] = category
                    updateFilteredCategories()
                }
            } else {
                errorMessage = "Failed to update category"
            }
        }
    }
    
    func deleteCategory(_ category: Category) {
        guard let categoryId = category.id else { return }
        
        Task {
            let success = await categoryService.deleteCategory(categoryId)
            if success {
                categories.removeAll { $0.id == categoryId }
                updateFilteredCategories()
                
                if selectedCategory?.id == categoryId {
                    selectedCategory = nil
                }
            } else {
                errorMessage = "Failed to delete category"
            }
        }
    }
    
    func selectCategory(_ category: Category) {
        selectedCategory = category
        
        // Update category stats
        if let categoryId = category.id {
            Task {
                await categoryService.updateCategoryStats(categoryId, userId: getCurrentUserId(), action: .view)
            }
        }
    }
    
    func clearSelection() {
        selectedCategory = nil
    }
    
    func getSubcategories(for parentCategory: Category) -> [Category] {
        guard let parentId = parentCategory.id else { return [] }
        return categories.filter { $0.parentCategoryId == parentId }
    }
    
    func getRootCategories() -> [Category] {
        return categories.filter { $0.parentCategoryId == nil }
    }
    
    func getCategoryHierarchy() -> [CategoryNode] {
        return CategoryUtilities.buildCategoryHierarchy(categories)
    }
    
    // MARK: - Private Methods
    private func setupBindings() {
        // Update filtered categories when search text or sort option changes
        Publishers.CombineLatest($searchText, $sortOption)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _, _ in
                self?.updateFilteredCategories()
            }
            .store(in: &cancellables)
        
        // Listen to category service updates
        categoryService.$categories
            .receive(on: DispatchQueue.main)
            .sink { [weak self] categories in
                self?.categories = categories
                self?.updateFilteredCategories()
            }
            .store(in: &cancellables)
        
        categoryService.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] errorMessage in
                self?.errorMessage = errorMessage
            }
            .store(in: &cancellables)
        
        categoryService.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.isLoading = isLoading
            }
            .store(in: &cancellables)
    }
    
    private func updateFilteredCategories() {
        let filtered = CategoryUtilities.filterCategories(categories, searchText: searchText)
        filteredCategories = CategoryUtilities.sortCategories(filtered, by: sortOption)
    }
    
    private func getCurrentUserId() -> String? {
        // This would typically get the current user ID from AuthState or similar
        return "current_user_id" // Placeholder
    }
}

// MARK: - CategoryViewModel Extensions
extension CategoryViewModel {
    var hasCategories: Bool {
        !categories.isEmpty
    }
    
    var systemCategories: [Category] {
        categories.filter { $0.isSystem }
    }
    
    var userCategories: [Category] {
        categories.filter { !$0.isSystem }
    }
    
    var popularCategories: [Category] {
        Array(categories.sorted { $0.messageCount > $1.messageCount }.prefix(5))
    }
    
    var recentCategories: [Category] {
        Array(categories.compactMap { category in
            guard let lastUsed = category.lastUsedDate else { return nil }
            return (category, lastUsed)
        }
        .sorted { $0.1 > $1.1 }
        .prefix(5)
        .map { $0.0 })
    }
}