import Foundation
import SwiftUI
import Combine

@MainActor
class TagSuggestionViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var suggestions: [TagSuggestion] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentContent = ""
    @Published var selectedCategory: Category?
    @Published var userHistory: [String] = []
    
    // MARK: - Private Properties
    private let categoryService = CategoryService()
    private var cancellables = Set<AnyCancellable>()
    private var suggestionTask: Task<Void, Never>?
    
    // MARK: - Computed Properties
    var hasHighConfidenceSuggestions: Bool {
        suggestions.contains { $0.confidence > 0.8 }
    }
    
    var groupedSuggestions: [SuggestionReason: [TagSuggestion]] {
        Dictionary(grouping: suggestions) { $0.reason }
    }
    
    var topSuggestions: [TagSuggestion] {
        Array(suggestions.prefix(5))
    }
    
    // MARK: - Initialization
    init() {
        setupBindings()
        loadUserHistory()
    }
    
    // MARK: - Public Methods
    func generateSuggestions(
        for content: String,
        category: Category? = nil,
        existingTags: [String] = []
    ) {
        // Cancel any existing suggestion task
        suggestionTask?.cancel()
        
        // Update current state
        currentContent = content
        selectedCategory = category
        
        // Start loading
        isLoading = true
        errorMessage = nil
        
        // Generate suggestions with debounce
        suggestionTask = Task {
            // Add small delay to debounce rapid calls
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
            
            // Check if task was cancelled
            guard !Task.isCancelled else { return }
            
            do {
                let newSuggestions = await categoryService.generateTagSuggestions(
                    for: content,
                    category: category,
                    userHistory: userHistory,
                    existingTags: existingTags
                )
                
                // Check if task was cancelled before updating UI
                guard !Task.isCancelled else { return }
                
                await MainActor.run {
                    self.suggestions = newSuggestions
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
    
    func refreshSuggestions() {
        generateSuggestions(
            for: currentContent,
            category: selectedCategory,
            existingTags: []
        )
    }
    
    func acceptSuggestion(_ suggestion: TagSuggestion) {
        // Add to user history for future suggestions
        addToUserHistory(suggestion.tagName)
        
        // Track suggestion acceptance for ML improvement
        trackSuggestionAcceptance(suggestion)
    }
    
    func rejectSuggestion(_ suggestion: TagSuggestion) {
        // Remove from current suggestions
        suggestions.removeAll { $0.id == suggestion.id }
        
        // Track suggestion rejection for ML improvement
        trackSuggestionRejection(suggestion)
    }
    
    func getSuggestionsForReason(_ reason: SuggestionReason) -> [TagSuggestion] {
        return suggestions.filter { $0.reason == reason }
    }
    
    func getSuggestionsFromSource(_ source: SuggestionSource) -> [TagSuggestion] {
        return suggestions.filter { $0.source == source }
    }
    
    func clearSuggestions() {
        suggestions.removeAll()
        currentContent = ""
        selectedCategory = nil
        isLoading = false
        errorMessage = nil
        
        // Cancel any ongoing task
        suggestionTask?.cancel()
    }
    
    func updateContent(_ content: String) {
        if content != currentContent {
            generateSuggestions(for: content, category: selectedCategory)
        }
    }
    
    func updateCategory(_ category: Category?) {
        if category?.id != selectedCategory?.id {
            generateSuggestions(for: currentContent, category: category)
        }
    }
    
    // MARK: - User History Management
    func addToUserHistory(_ tagName: String) {
        let normalizedTag = tagName.lowercased()
        
        // Remove if already exists to move to front
        userHistory.removeAll { $0 == normalizedTag }
        
        // Add to front
        userHistory.insert(normalizedTag, at: 0)
        
        // Keep only recent tags
        if userHistory.count > CategoryConstants.Defaults.maxRecentTags {
            userHistory = Array(userHistory.prefix(CategoryConstants.Defaults.maxRecentTags))
        }
        
        // Save to persistent storage
        saveUserHistory()
    }
    
    func clearUserHistory() {
        userHistory.removeAll()
        saveUserHistory()
    }
    
    // MARK: - Private Methods
    private func setupBindings() {
        // Listen to category service updates
        categoryService.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] errorMessage in
                if let error = errorMessage {
                    self?.errorMessage = error
                }
            }
            .store(in: &cancellables)
    }
    
    private func loadUserHistory() {
        // Load from UserDefaults or similar persistent storage
        if let saved = UserDefaults.standard.array(forKey: "tagHistory") as? [String] {
            userHistory = saved
        }
    }
    
    private func saveUserHistory() {
        UserDefaults.standard.set(userHistory, forKey: "tagHistory")
    }
    
    private func trackSuggestionAcceptance(_ suggestion: TagSuggestion) {
        // This would typically send analytics data to improve ML models
        // For now, just log the acceptance
        print("Suggestion accepted: \(suggestion.tagName) with confidence \(suggestion.confidence)")
        
        // Update user history with higher weight for accepted suggestions
        addToUserHistory(suggestion.tagName)
    }
    
    private func trackSuggestionRejection(_ suggestion: TagSuggestion) {
        // This would typically send analytics data to improve ML models
        print("Suggestion rejected: \(suggestion.tagName) with confidence \(suggestion.confidence)")
    }
}

// MARK: - Mock Data Support
extension TagSuggestionViewModel {
    func loadMockSuggestions(for content: String) {
        suggestions = TagSuggestion.mock(for: content)
        isLoading = false
    }
    
    static func preview() -> TagSuggestionViewModel {
        let viewModel = TagSuggestionViewModel()
        viewModel.loadMockSuggestions(for: "Happy birthday to my amazing friend!")
        return viewModel
    }
}

// MARK: - Suggestion Filtering and Ranking
extension TagSuggestionViewModel {
    func getHighConfidenceSuggestions() -> [TagSuggestion] {
        return suggestions.filter { $0.confidence > 0.7 }
    }
    
    func getMediumConfidenceSuggestions() -> [TagSuggestion] {
        return suggestions.filter { $0.confidence > 0.4 && $0.confidence <= 0.7 }
    }
    
    func getLowConfidenceSuggestions() -> [TagSuggestion] {
        return suggestions.filter { $0.confidence <= 0.4 }
    }
    
    func getSuggestionsByConfidence() -> [TagSuggestion] {
        return suggestions.sorted { $0.confidence > $1.confidence }
    }
    
    func getSuggestionsBySource() -> [TagSuggestion] {
        return suggestions.sorted { $0.source.priority > $1.source.priority }
    }
}