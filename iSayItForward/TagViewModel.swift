import Foundation
import SwiftUI
import Combine

@MainActor
class TagViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var tags: [Tag] = []
    @Published var filteredTags: [Tag] = []
    @Published var selectedTags: [Tag] = []
    @Published var searchText = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var newTagName = ""
    @Published var showingTagInput = false
    
    // MARK: - Private Properties
    private let categoryService = CategoryService()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var popularTags: [Tag] {
        Array(tags.sorted { $0.usageCount > $1.usageCount }.prefix(20))
    }
    
    var trendingTags: [Tag] {
        Array(tags.sorted { $0.trendingScore > $1.trendingScore }.prefix(10))
    }
    
    var recentTags: [Tag] {
        Array(tags.compactMap { tag in
            guard let lastUsed = tag.lastUsedDate else { return nil }
            return (tag, lastUsed)
        }
        .sorted { $0.1 > $1.1 }
        .prefix(10)
        .map { $0.0 })
    }
    
    var selectedTagNames: [String] {
        selectedTags.map { $0.name }
    }
    
    var canAddMoreTags: Bool {
        selectedTags.count < CategoryConstants.maxTagsPerMessage
    }
    
    // MARK: - Initialization
    init() {
        setupBindings()
        loadTags()
    }
    
    // MARK: - Public Methods
    func loadTags() {
        isLoading = true
        
        Task {
            await categoryService.fetchTags()
            
            self.tags = categoryService.tags
            self.updateFilteredTags()
            self.isLoading = false
        }
    }
    
    func addTag(_ tagName: String) {
        let trimmed = tagName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Validate tag
        switch TagValidation.validateTag(trimmed) {
        case .success(let validTagName):
            // Check if already selected
            if selectedTags.contains(where: { $0.name.lowercased() == validTagName }) {
                errorMessage = CategoryConstants.ErrorMessages.duplicateTag
                return
            }
            
            // Check tag limit
            if !canAddMoreTags {
                errorMessage = CategoryConstants.ErrorMessages.tooManyTags
                return
            }
            
            // Find existing tag or create new one
            if let existingTag = tags.first(where: { $0.normalizedName == validTagName }) {
                selectedTags.append(existingTag)
            } else {
                // Create new tag
                let newTag = Tag(name: validTagName, createdBy: getCurrentUserId())
                selectedTags.append(newTag)
                
                // Save to database
                Task {
                    if let savedTag = await categoryService.createOrUpdateTag(validTagName, createdBy: getCurrentUserId()) {
                        // Update tags list
                        if !self.tags.contains(where: { $0.normalizedName == savedTag.normalizedName }) {
                            self.tags.append(savedTag)
                            self.updateFilteredTags()
                        }
                    }
                }
            }
            
            clearInput()
            
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
    
    func addMultipleTags(from input: String) {
        let tagNames = TagValidation.parseTagInput(input)
        
        switch TagValidation.validateTags(tagNames, existingTags: selectedTagNames) {
        case .success(let validTags):
            for tagName in validTags {
                if canAddMoreTags {
                    addTag(tagName)
                }
            }
            
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
    
    func removeTag(_ tag: Tag) {
        selectedTags.removeAll { $0.id == tag.id || $0.name == tag.name }
    }
    
    func removeTag(at index: Int) {
        guard index < selectedTags.count else { return }
        selectedTags.remove(at: index)
    }
    
    func clearSelectedTags() {
        selectedTags.removeAll()
    }
    
    func selectTag(_ tag: Tag) {
        if !selectedTags.contains(where: { $0.name == tag.name }) && canAddMoreTags {
            selectedTags.append(tag)
            
            // Update usage statistics
            Task {
                _ = await categoryService.createOrUpdateTag(tag.name, createdBy: getCurrentUserId())
            }
        }
    }
    
    func toggleTag(_ tag: Tag) {
        if selectedTags.contains(where: { $0.name == tag.name }) {
            removeTag(tag)
        } else {
            selectTag(tag)
        }
    }
    
    func isTagSelected(_ tag: Tag) -> Bool {
        selectedTags.contains(where: { $0.name == tag.name })
    }
    
    func getTagFontSize(_ tag: Tag) -> CGFloat {
        return CategoryUtilities.calculateTagFontSize(tag, in: tags)
    }
    
    func searchTags(_ query: String) -> [Tag] {
        return categoryService.searchTags(query)
    }
    
    func clearInput() {
        newTagName = ""
        errorMessage = nil
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Private Methods
    private func setupBindings() {
        // Update filtered tags when search text changes
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateFilteredTags()
            }
            .store(in: &cancellables)
        
        // Listen to category service updates
        categoryService.$tags
            .receive(on: DispatchQueue.main)
            .sink { [weak self] tags in
                self?.tags = tags
                self?.updateFilteredTags()
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
    
    private func updateFilteredTags() {
        if searchText.isEmpty {
            filteredTags = tags
        } else {
            let lowercased = searchText.lowercased()
            filteredTags = tags.filter { tag in
                tag.name.lowercased().contains(lowercased) ||
                tag.normalizedName.contains(lowercased)
            }
        }
    }
    
    private func getCurrentUserId() -> String? {
        // This would typically get the current user ID from AuthState or similar
        return "current_user_id" // Placeholder
    }
}

// MARK: - Tag Cloud Support
extension TagViewModel {
    func getTagCloudArrangement() -> [[Tag]] {
        return CategoryUtilities.arrangeTagsInCloud(popularTags)
    }
    
    func getTagsByUsage() -> [Tag] {
        return tags.sorted { $0.usageCount > $1.usageCount }
    }
    
    func getTagsByTrending() -> [Tag] {
        return tags.sorted { $0.trendingScore > $1.trendingScore }
    }
    
    func getRelatedTags(for tag: Tag) -> [Tag] {
        let relatedNames = Set(tag.relatedTags)
        return tags.filter { relatedNames.contains($0.name) }
    }
}