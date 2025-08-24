import SwiftUI

struct TagCloudView: View {
    @StateObject private var viewModel = TagViewModel()
    @State private var selectedTags: Set<String> = []
    @State private var cloudMode: CloudMode = .popular
    
    // Optional closures for tag interaction
    let onTagSelected: ((Tag) -> Void)?
    let onTagDeselected: ((Tag) -> Void)?
    let allowMultipleSelection: Bool
    let maxSelections: Int
    
    init(
        onTagSelected: ((Tag) -> Void)? = nil,
        onTagDeselected: ((Tag) -> Void)? = nil,
        allowMultipleSelection: Bool = true,
        maxSelections: Int = CategoryConstants.maxTagsPerMessage
    ) {
        self.onTagSelected = onTagSelected
        self.onTagDeselected = onTagDeselected
        self.allowMultipleSelection = allowMultipleSelection
        self.maxSelections = maxSelections
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with mode selector
            headerSection
            
            // Tag cloud content
            if viewModel.isLoading {
                loadingView
            } else if currentTags.isEmpty {
                emptyStateView
            } else {
                tagCloudContent
            }
        }
        .background(Color.mainAppGradient.ignoresSafeArea())
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Title
            HStack {
                VStack(alignment: .leading) {
                    Text("Tag Cloud")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(cloudModeDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if allowMultipleSelection && !selectedTags.isEmpty {
                    Button("Clear") {
                        clearSelection()
                    }
                    .font(.caption)
                    .foregroundColor(.brandYellow)
                }
            }
            
            // Mode selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(CloudMode.allCases, id: \.self) { mode in
                        Button {
                            cloudMode = mode
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: mode.iconName)
                                Text(mode.displayName)
                            }
                            .font(.caption)
                            .foregroundColor(cloudMode == mode ? .white : .primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(cloudMode == mode ? Color.brandYellow : Color.white.opacity(0.7))
                            )
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            if allowMultipleSelection {
                selectionIndicator
            }
        }
        .padding()
        .background(.white.opacity(0.1))
    }
    
    // MARK: - Selection Indicator
    private var selectionIndicator: some View {
        HStack {
            Text("\(selectedTags.count) of \(maxSelections) selected")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Spacer()
            
            ProgressView(value: Double(selectedTags.count), total: Double(maxSelections))
                .progressViewStyle(LinearProgressViewStyle(tint: .brandYellow))
                .frame(width: 80)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.5))
        )
    }
    
    // MARK: - Tag Cloud Content
    private var tagCloudContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(tagRows, id: \.self) { row in
                    TagRowView(
                        tags: row,
                        selectedTags: $selectedTags,
                        onTagSelected: handleTagSelection,
                        onTagDeselected: handleTagDeselection,
                        allowMultipleSelection: allowMultipleSelection,
                        maxSelections: maxSelections
                    )
                }
            }
            .padding()
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading tags...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "tag")
                .font(.system(size: 60))
                .foregroundColor(.brandYellow.opacity(0.6))
            
            VStack(spacing: 12) {
                Text("No Tags Available")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Tags will appear here as messages are created and tagged")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                viewModel.loadTags()
            } label: {
                Text("Refresh")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.brandYellow)
                    .cornerRadius(12)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Computed Properties
    private var currentTags: [Tag] {
        switch cloudMode {
        case .popular:
            return viewModel.popularTags
        case .trending:
            return viewModel.trendingTags
        case .recent:
            return viewModel.recentTags
        case .all:
            return Array(viewModel.tags.prefix(CategoryConstants.tagCloudMaxTags))
        }
    }
    
    private var tagRows: [[Tag]] {
        CategoryUtilities.arrangeTagsInCloud(currentTags)
    }
    
    private var cloudModeDescription: String {
        switch cloudMode {
        case .popular:
            return "Most used tags"
        case .trending:
            return "Tags gaining popularity"
        case .recent:
            return "Recently used tags"
        case .all:
            return "All available tags"
        }
    }
    
    // MARK: - Actions
    private func handleTagSelection(_ tag: Tag) {
        if allowMultipleSelection {
            if selectedTags.count < maxSelections {
                selectedTags.insert(tag.name)
                onTagSelected?(tag)
            }
        } else {
            selectedTags = [tag.name]
            onTagSelected?(tag)
        }
    }
    
    private func handleTagDeselection(_ tag: Tag) {
        selectedTags.remove(tag.name)
        onTagDeselected?(tag)
    }
    
    private func clearSelection() {
        let deselectedTags = selectedTags.compactMap { tagName in
            currentTags.first { $0.name == tagName }
        }
        
        selectedTags.removeAll()
        
        for tag in deselectedTags {
            onTagDeselected?(tag)
        }
    }
}

// MARK: - Tag Row View
struct TagRowView: View {
    let tags: [Tag]
    @Binding var selectedTags: Set<String>
    let onTagSelected: (Tag) -> Void
    let onTagDeselected: (Tag) -> Void
    let allowMultipleSelection: Bool
    let maxSelections: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(tags, id: \.id) { tag in
                TagCloudButton(
                    tag: tag,
                    isSelected: selectedTags.contains(tag.name),
                    isSelectable: canSelectTag(tag),
                    onTap: {
                        handleTagTap(tag)
                    }
                )
            }
            
            Spacer(minLength: 0)
        }
    }
    
    private func canSelectTag(_ tag: Tag) -> Bool {
        if selectedTags.contains(tag.name) {
            return true // Can always deselect
        }
        
        if !allowMultipleSelection {
            return selectedTags.isEmpty
        }
        
        return selectedTags.count < maxSelections
    }
    
    private func handleTagTap(_ tag: Tag) {
        if selectedTags.contains(tag.name) {
            onTagDeselected(tag)
        } else if canSelectTag(tag) {
            onTagSelected(tag)
        }
    }
}

// MARK: - Tag Cloud Button
struct TagCloudButton: View {
    let tag: Tag
    let isSelected: Bool
    let isSelectable: Bool
    let onTap: () -> Void
    
    @StateObject private var tagViewModel = TagViewModel()
    
    var body: some View {
        Button(action: onTap) {
            Text("#\(tag.name)")
                .font(.system(size: tagViewModel.getTagFontSize(tag)))
                .fontWeight(isSelected ? .bold : .regular)
                .foregroundColor(textColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(backgroundColor)
                        .stroke(borderColor, lineWidth: isSelected ? 2 : 0)
                )
                .opacity(isSelectable ? 1.0 : 0.5)
                .scaleEffect(isSelected ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .disabled(!isSelectable)
    }
    
    private var textColor: Color {
        if isSelected {
            return .white
        } else {
            return .primary
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return .brandYellow
        } else {
            let alpha = min(0.8, max(0.3, tag.trendingScore))
            return .brandYellow.opacity(alpha)
        }
    }
    
    private var borderColor: Color {
        return .brandYellow.opacity(0.8)
    }
}

// MARK: - Supporting Types
enum CloudMode: String, CaseIterable {
    case popular = "popular"
    case trending = "trending"
    case recent = "recent"
    case all = "all"
    
    var displayName: String {
        switch self {
        case .popular: return "Popular"
        case .trending: return "Trending"
        case .recent: return "Recent"
        case .all: return "All Tags"
        }
    }
    
    var iconName: String {
        switch self {
        case .popular: return "flame.fill"
        case .trending: return "chart.line.uptrend.xyaxis"
        case .recent: return "clock.fill"
        case .all: return "tag.fill"
        }
    }
}

// MARK: - Preview
struct TagCloudView_Previews: PreviewProvider {
    static var previews: some View {
        TagCloudView { tag in
            print("Selected: \(tag.name)")
        } onTagDeselected: { tag in
            print("Deselected: \(tag.name)")
        }
    }
}