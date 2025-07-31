import SwiftUI

struct TagSelectionView: View {
    @StateObject private var viewModel = TagViewModel()
    @StateObject private var suggestionViewModel = TagSuggestionViewModel()
    @FocusState private var isInputFocused: Bool
    
    // Configuration
    let maxTags: Int
    let placeholder: String
    let showSuggestions: Bool
    let onTagsChanged: ([String]) -> Void
    
    // Optional content context for suggestions
    @State private var contentForSuggestions: String = ""
    @State private var categoryForSuggestions: Category?
    
    init(
        maxTags: Int = CategoryConstants.maxTagsPerMessage,
        placeholder: String = "Add tags...",
        showSuggestions: Bool = true,
        onTagsChanged: @escaping ([String]) -> Void
    ) {
        self.maxTags = maxTags
        self.placeholder = placeholder
        self.showSuggestions = showSuggestions
        self.onTagsChanged = onTagsChanged
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Selected tags display
            if !viewModel.selectedTags.isEmpty {
                selectedTagsSection
            }
            
            // Tag input section
            tagInputSection
            
            // Suggestions (if enabled)
            if showSuggestions {
                suggestionsSection
            }
            
            // Popular tags for quick selection
            quickTagsSection
        }
        .onChange(of: viewModel.selectedTagNames) { tags in
            onTagsChanged(tags)
        }
        .onChange(of: contentForSuggestions) { content in
            if showSuggestions && !content.isEmpty {
                suggestionViewModel.generateSuggestions(
                    for: content,
                    category: categoryForSuggestions,
                    existingTags: viewModel.selectedTagNames
                )
            }
        }
    }
    
    // MARK: - Selected Tags Section
    private var selectedTagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Selected Tags (\(viewModel.selectedTags.count)/\(maxTags))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Clear All") {
                    viewModel.clearSelectedTags()
                }
                .font(.caption)
                .foregroundColor(.brandYellow)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(viewModel.selectedTags.enumerated()), id: \.element.id) { index, tag in
                        SelectedTagChip(
                            tag: tag,
                            onRemove: {
                                viewModel.removeTag(at: index)
                            }
                        )
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.9))
        )
    }
    
    // MARK: - Tag Input Section
    private var tagInputSection: some View {
        VStack(spacing: 12) {
            HStack {
                TextField(placeholder, text: $viewModel.newTagName)
                    .focused($isInputFocused)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        addCurrentTag()
                    }
                
                Button {
                    addCurrentTag()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(canAddTag ? .brandYellow : .gray)
                }
                .disabled(!canAddTag)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white.opacity(0.9))
                    .stroke(isInputFocused ? Color.brandYellow : Color.clear, lineWidth: 2)
            )
            
            // Input validation feedback
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }
            
            // Input help text
            Text("Separate multiple tags with spaces, commas, or line breaks")
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
    }
    
    // MARK: - Suggestions Section
    private var suggestionsSection: some View {
        Group {
            if suggestionViewModel.isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Generating suggestions...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            } else if !suggestionViewModel.suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Suggested Tags")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ForEach(suggestionViewModel.topSuggestions, id: \.id) { suggestion in
                            SuggestionChip(
                                suggestion: suggestion,
                                onAccept: {
                                    acceptSuggestion(suggestion)
                                }
                            )
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.white.opacity(0.8))
                )
            }
        }
    }
    
    // MARK: - Quick Tags Section
    private var quickTagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Popular Tags")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.popularTags.prefix(10), id: \.id) { tag in
                        QuickTagButton(
                            tag: tag,
                            isSelected: viewModel.isTagSelected(tag),
                            onTap: {
                                viewModel.toggleTag(tag)
                            }
                        )
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.8))
        )
    }
    
    // MARK: - Computed Properties
    private var canAddTag: Bool {
        !viewModel.newTagName.isEmpty && 
        viewModel.canAddMoreTags &&
        TagValidation.validateTag(viewModel.newTagName).isSuccess
    }
    
    // MARK: - Actions
    private func addCurrentTag() {
        guard canAddTag else { return }
        
        let input = viewModel.newTagName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if input.contains(" ") || input.contains(",") || input.contains("\n") {
            // Multiple tags
            viewModel.addMultipleTags(from: input)
        } else {
            // Single tag
            viewModel.addTag(input)
        }
    }
    
    private func acceptSuggestion(_ suggestion: TagSuggestion) {
        viewModel.addTag(suggestion.tagName)
        suggestionViewModel.acceptSuggestion(suggestion)
    }
    
    // MARK: - Public Methods
    func updateContent(_ content: String) {
        contentForSuggestions = content
    }
    
    func updateCategory(_ category: Category?) {
        categoryForSuggestions = category
    }
    
    func setSelectedTags(_ tags: [String]) {
        viewModel.clearSelectedTags()
        for tagName in tags {
            viewModel.addTag(tagName)
        }
    }
}

// MARK: - Selected Tag Chip
struct SelectedTagChip: View {
    let tag: Tag
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            Text("#\(tag.name)")
                .font(.caption)
                .fontWeight(.medium)
            
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(.brandYellow)
        )
    }
}

// MARK: - Suggestion Chip
struct SuggestionChip: View {
    let suggestion: TagSuggestion
    let onAccept: () -> Void
    
    var body: some View {
        Button(action: onAccept) {
            HStack(spacing: 6) {
                Image(systemName: suggestion.reason.iconName)
                    .font(.caption2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("#\(suggestion.tagName)")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Text("\(suggestion.confidencePercentage)% • \(suggestion.reason.displayName)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .foregroundColor(.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.white)
                    .stroke(Color.brandYellow.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - Quick Tag Button
struct QuickTagButton: View {
    let tag: Tag
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text("#\(tag.name)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? .brandYellow : .white.opacity(0.8))
                        .stroke(Color.brandYellow.opacity(0.5), lineWidth: 1)
                )
        }
    }
}

// MARK: - Preview
struct TagSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            TagSelectionView { tags in
                print("Tags changed: \(tags)")
            }
            .padding()
        }
        .background(Color.mainAppGradient)
    }
}