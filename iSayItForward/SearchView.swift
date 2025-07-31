import SwiftUI

// MARK: - Main Search View
struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @State private var showingFilters = false
    @State private var showingHistory = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Header
                searchHeader
                
                // Search Content
                if viewModel.showLoadingState {
                    loadingView
                } else if viewModel.showEmptyState {
                    emptyStateView
                } else if viewModel.showResults {
                    searchResultsView
                } else {
                    discoveryView
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingFilters) {
                SearchFiltersView(
                    filter: $viewModel.currentFilter,
                    onApply: { filter in
                        viewModel.applyFilter(filter)
                        showingFilters = false
                    }
                )
            }
            .sheet(isPresented: $showingHistory) {
                SearchHistoryView(
                    searchHistory: viewModel.searchHistory,
                    onSelectHistory: { entry in
                        viewModel.searchFromHistory(entry)
                        showingHistory = false
                    },
                    onClearHistory: {
                        viewModel.clearSearchHistory()
                    }
                )
            }
        }
        .onAppear {
            viewModel.trackSearchInteraction("search_view_appeared")
        }
    }
    
    // MARK: - Search Header
    private var searchHeader: some View {
        VStack(spacing: 12) {
            // Search Bar
            HStack {
                searchBar
                filterButton
            }
            .padding(.horizontal, 16)
            
            // Quick Filter Chips
            if !viewModel.isEmpty || viewModel.hasSearched {
                quickFiltersScrollView
            }
            
            // Search Suggestions
            if viewModel.showingSuggestions {
                suggestionsView
            }
        }
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search messages, users, or templates...", text: $viewModel.searchQuery)
                .textFieldStyle(PlainTextFieldStyle())
                .onSubmit {
                    viewModel.performSearch()
                }
                .onTapGesture {
                    if viewModel.isEmpty {
                        showingHistory = true
                    }
                }
            
            if !viewModel.searchQuery.isEmpty {
                Button("Clear") {
                    viewModel.clearSearch()
                }
                .foregroundColor(.blue)
                .font(.caption)
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private var filterButton: some View {
        Button(action: {
            showingFilters = true
            viewModel.trackSearchInteraction("filter_button_tapped")
        }) {
            HStack {
                Image(systemName: "line.3.horizontal.decrease.circle")
                
                if viewModel.activeFilterBadgeCount > 0 {
                    Text("\(viewModel.activeFilterBadgeCount)")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
            }
        }
        .foregroundColor(.blue)
        .padding(8)
    }
    
    // MARK: - Quick Filters
    private var quickFiltersScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                quickFilterChip("Messages", type: .message)
                quickFilterChip("Users", type: .user)
                quickFilterChip("Templates", type: .template)
                quickFilterChip("Categories", type: .category)
                
                Spacer(minLength: 16)
            }
            .padding(.horizontal, 16)
        }
    }
    
    private func quickFilterChip(_ title: String, type: SearchResultType) -> some View {
        Button(action: {
            viewModel.toggleFilter(for: type)
            viewModel.trackSearchInteraction("quick_filter_tapped")
        }) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    viewModel.currentFilter.resultTypes.contains(type) ?
                    Color.blue : Color(.systemGray5)
                )
                .foregroundColor(
                    viewModel.currentFilter.resultTypes.contains(type) ?
                    .white : .primary
                )
                .clipShape(Capsule())
        }
    }
    
    // MARK: - Suggestions
    private var suggestionsView: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(viewModel.displaySuggestions.prefix(5), id: \.self) { suggestion in
                Button(action: {
                    viewModel.searchWithSuggestion(suggestion)
                    viewModel.trackSearchInteraction("suggestion_selected")
                }) {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.gray)
                            .font(.caption)
                        
                        Text(suggestion)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.left")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                
                if suggestion != viewModel.displaySuggestions.last {
                    Divider()
                        .padding(.leading, 40)
                }
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        .padding(.horizontal, 16)
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Searching...")
                .font(.headline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text("No Results Found")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Try adjusting your search terms or filters")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                Button("Clear Filters") {
                    viewModel.clearFilters()
                }
                .buttonStyle(SecondaryActionButtonStyle())
                
                Button("View Search History") {
                    showingHistory = true
                }
                .buttonStyle(PrimaryActionButtonStyle())
            }
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Search Results
    private var searchResultsView: some View {
        VStack(spacing: 0) {
            // Results Summary
            resultsSummaryView
            
            // Results List
            SearchResultsView(
                results: viewModel.paginatedResults,
                onSelectResult: { result in
                    viewModel.selectResult(result)
                }
            )
            
            // Pagination
            if viewModel.totalPages > 1 {
                paginationView
            }
        }
    }
    
    private var resultsSummaryView: some View {
        HStack {
            Text(viewModel.resultsSummary)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Spacer()
            
            if viewModel.totalPages > 1 {
                Text(viewModel.currentPageDisplay)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
    
    private var paginationView: some View {
        HStack {
            Button("Previous") {
                viewModel.loadPreviousPage()
            }
            .disabled(!viewModel.canLoadPreviousPage)
            
            Spacer()
            
            Text("\(viewModel.currentPage + 1) of \(viewModel.totalPages)")
                .font(.caption)
                .foregroundColor(.gray)
            
            Spacer()
            
            Button("Next") {
                viewModel.loadNextPage()
            }
            .disabled(!viewModel.canLoadNextPage)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .border(Color(.systemGray4), width: 0.5)
    }
    
    // MARK: - Discovery View
    private var discoveryView: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Search suggestions
                if !viewModel.recentSearches.isEmpty {
                    recentSearchesSection
                }
                
                // Trending content
                TrendingView()
                
                // Popular categories
                popularCategoriesSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
        }
    }
    
    private var recentSearchesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Searches")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Clear") {
                    viewModel.clearSearchHistory()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            FlowLayout(alignment: .leading, spacing: 8) {
                ForEach(viewModel.recentSearches.prefix(8), id: \.self) { search in
                    Button(search) {
                        viewModel.searchWithSuggestion(search)
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .clipShape(Capsule())
                }
            }
        }
    }
    
    private var popularCategoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Popular Categories")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(["Birthday", "Thank You", "Congratulations", "Get Well"], id: \.self) { category in
                    Button(action: {
                        viewModel.searchWithSuggestion(category.lowercased())
                    }) {
                        VStack {
                            Image(systemName: iconForCategory(category))
                                .font(.title2)
                                .foregroundColor(.blue)
                            
                            Text(category)
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
    
    private func iconForCategory(_ category: String) -> String {
        switch category {
        case "Birthday": return "gift"
        case "Thank You": return "heart"
        case "Congratulations": return "star"
        case "Get Well": return "heart.text.square"
        default: return "folder"
        }
    }
}

// MARK: - Flow Layout Helper
struct FlowLayout: Layout {
    var alignment: Alignment = .center
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            alignment: alignment,
            spacing: spacing
        )
        return result.bounds
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            alignment: alignment,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX,
                                    y: bounds.minY + result.frames[index].minY),
                         proposal: ProposedViewSize(result.frames[index].size))
        }
    }
    
    struct FlowResult {
        var bounds = CGSize.zero
        var frames: [CGRect] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, alignment: Alignment, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
                currentX += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }
            
            bounds = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

// MARK: - Preview
struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView()
    }
}