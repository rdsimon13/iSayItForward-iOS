import Foundation
import SwiftUI
import Combine

@MainActor
class CategorySelectionViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var categories: [Category] = []
    @Published var selectedCategories: [Category] = []
    @Published var searchText = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingCreateCategory = false
    @Published var selectionMode: SelectionMode = .single
    @Published var maxSelections = 3
    
    // MARK: - Private Properties
    private let categoryService = CategoryService()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var filteredCategories: [Category] {
        CategoryUtilities.filterCategories(categories, searchText: searchText)
    }
    
    var selectedCategoryIds: [String] {
        selectedCategories.compactMap { $0.id }
    }
    
    var selectedCategoryNames: [String] {
        selectedCategories.map { $0.name }
    }
    
    var canAddMoreCategories: Bool {
        selectedCategories.count < maxSelections
    }
    
    var hasSelectedCategories: Bool {
        !selectedCategories.isEmpty
    }
    
    var systemCategories: [Category] {
        categories.filter { $0.isSystem }
    }
    
    var userCategories: [Category] {
        categories.filter { !$0.isSystem }
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
    
    var popularCategories: [Category] {
        Array(categories.sorted { $0.messageCount > $1.messageCount }.prefix(5))
    }
    
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
            self.isLoading = false
        }
    }
    
    func selectCategory(_ category: Category) {
        switch selectionMode {
        case .single:
            selectedCategories = [category]
        case .multiple:
            if !selectedCategories.contains(where: { $0.id == category.id }) && canAddMoreCategories {
                selectedCategories.append(category)
            }
        }
        
        // Update usage statistics
        if let categoryId = category.id {
            Task {
                await categoryService.updateCategoryStats(categoryId, userId: getCurrentUserId(), action: .view)
            }
        }
    }
    
    func deselectCategory(_ category: Category) {
        selectedCategories.removeAll { $0.id == category.id }
    }
    
    func toggleCategorySelection(_ category: Category) {
        if isCategorySelected(category) {
            deselectCategory(category)
        } else {
            selectCategory(category)
        }
    }
    
    func isCategorySelected(_ category: Category) -> Bool {
        selectedCategories.contains(where: { $0.id == category.id })
    }
    
    func clearSelection() {
        selectedCategories.removeAll()
    }
    
    func setSelectionMode(_ mode: SelectionMode, maxSelections: Int = 3) {
        self.selectionMode = mode
        self.maxSelections = maxSelections
        
        // Adjust current selection based on new mode
        if mode == .single && selectedCategories.count > 1 {
            selectedCategories = Array(selectedCategories.prefix(1))
        } else if selectedCategories.count > maxSelections {
            selectedCategories = Array(selectedCategories.prefix(maxSelections))
        }
    }
    
    func searchCategories(_ query: String) {
        searchText = query
    }
    
    func clearSearch() {
        searchText = ""
    }
    
    func getCategoryHierarchy() -> [CategoryNode] {
        return CategoryUtilities.buildCategoryHierarchy(categories)
    }
    
    func getSubcategories(for parentCategory: Category) -> [Category] {
        guard let parentId = parentCategory.id else { return [] }
        return categories.filter { $0.parentCategoryId == parentId }
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
                self.showingCreateCategory = false
                
                // Automatically select the new category if in single mode
                if selectionMode == .single {
                    selectCategory(newCategory)
                }
            } else {
                self.errorMessage = "Failed to create category"
            }
        }
    }
    
    func getSuggestedCategories(for content: String) -> [Category] {
        // Simple content-based category suggestion
        let lowercased = content.lowercased()
        
        return categories.filter { category in
            // Check if category name appears in content
            lowercased.contains(category.name.lowercased()) ||
            // Check if category description keywords appear in content
            category.description.lowercased().split(separator: " ").contains { keyword in
                lowercased.contains(keyword)
            }
        }.sorted { $0.messageCount > $1.messageCount } // Prefer popular categories
    }
    
    func getCategoriesForTags(_ tags: [String]) -> [Category] {
        // Find categories commonly used with these tags
        // This would typically query the database for messages with these tags
        // For now, return system categories as suggestions
        return systemCategories
    }
    
    // MARK: - Private Methods
    private func setupBindings() {
        // Listen to category service updates
        categoryService.$categories
            .receive(on: DispatchQueue.main)
            .sink { [weak self] categories in
                self?.categories = categories
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
    
    private func getCurrentUserId() -> String? {
        // This would typically get the current user ID from AuthState or similar
        return "current_user_id" // Placeholder
    }
}

// MARK: - Supporting Types
enum SelectionMode {
    case single
    case multiple
    
    var displayName: String {
        switch self {
        case .single: return "Single Selection"
        case .multiple: return "Multiple Selection"
        }
    }
}

// MARK: - CategorySelectionViewModel Extensions
extension CategorySelectionViewModel {
    func reset() {
        clearSelection()
        clearSearch()
        errorMessage = nil
    }
    
    func prepopulateSelection(with categories: [Category]) {
        selectedCategories = categories
    }
    
    func prepopulateSelection(with categoryIds: [String]) {
        selectedCategories = categories.filter { category in
            categoryIds.contains(category.id ?? "")
        }
    }
    
    func validateSelection() -> Bool {
        switch selectionMode {
        case .single:
            return selectedCategories.count == 1
        case .multiple:
            return !selectedCategories.isEmpty && selectedCategories.count <= maxSelections
        }
    }
    
    func getSelectionSummary() -> String {
        switch selectedCategories.count {
        case 0:
            return "No categories selected"
        case 1:
            return selectedCategories[0].displayName
        default:
            return "\(selectedCategories.count) categories selected"
        }
    }
}

// MARK: - Preview Support
extension CategorySelectionViewModel {
    static func preview() -> CategorySelectionViewModel {
        let viewModel = CategorySelectionViewModel()
        viewModel.categories = Category.systemCategories
        return viewModel
    }
}