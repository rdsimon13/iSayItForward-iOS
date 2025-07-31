import SwiftUI

// MARK: - Search Filters View
struct SearchFiltersView: View {
    @Binding var filter: SearchFilter
    let onApply: (SearchFilter) -> Void
    
    @State private var tempFilter: SearchFilter
    @Environment(\.presentationMode) var presentationMode
    
    init(filter: Binding<SearchFilter>, onApply: @escaping (SearchFilter) -> Void) {
        self._filter = filter
        self.onApply = onApply
        self._tempFilter = State(initialValue: filter.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Content Type Filters
                contentTypeSection
                
                // Date Range Filters
                dateRangeSection
                
                // Category Filters
                categorySection
                
                // Impact Score Filter
                impactScoreSection
                
                // Author Filters
                authorSection
                
                // Content Specific Filters
                contentSpecificSection
                
                // Sort Options
                sortSection
                
                // Reset Section
                resetSection
            }
            .navigationTitle("Search Filters")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Apply") {
                    onApply(tempFilter)
                }
                .fontWeight(.semibold)
            )
        }
    }
    
    // MARK: - Content Type Section
    private var contentTypeSection: some View {
        Section("Content Types") {
            ForEach(SearchResultType.allCases, id: \.self) { type in
                FilterToggleRow(
                    title: type.displayName,
                    icon: iconForType(type),
                    isOn: Binding(
                        get: { tempFilter.resultTypes.contains(type) },
                        set: { isOn in
                            if isOn {
                                tempFilter.resultTypes.insert(type)
                            } else {
                                tempFilter.resultTypes.remove(type)
                            }
                        }
                    )
                )
            }
        }
    }
    
    // MARK: - Date Range Section
    private var dateRangeSection: some View {
        Section("Date Range") {
            DatePicker(
                "Start Date",
                selection: Binding(
                    get: { tempFilter.dateRange.startDate ?? Date() },
                    set: { tempFilter.dateRange = DateRangeFilter(startDate: $0, endDate: tempFilter.dateRange.endDate) }
                ),
                displayedComponents: .date
            )
            .disabled(tempFilter.dateRange.startDate == nil)
            
            Toggle("Enable Start Date", isOn: Binding(
                get: { tempFilter.dateRange.startDate != nil },
                set: { enabled in
                    if enabled {
                        tempFilter.dateRange = DateRangeFilter(startDate: Date(), endDate: tempFilter.dateRange.endDate)
                    } else {
                        tempFilter.dateRange = DateRangeFilter(startDate: nil, endDate: tempFilter.dateRange.endDate)
                    }
                }
            ))
            
            DatePicker(
                "End Date",
                selection: Binding(
                    get: { tempFilter.dateRange.endDate ?? Date() },
                    set: { tempFilter.dateRange = DateRangeFilter(startDate: tempFilter.dateRange.startDate, endDate: $0) }
                ),
                displayedComponents: .date
            )
            .disabled(tempFilter.dateRange.endDate == nil)
            
            Toggle("Enable End Date", isOn: Binding(
                get: { tempFilter.dateRange.endDate != nil },
                set: { enabled in
                    if enabled {
                        tempFilter.dateRange = DateRangeFilter(startDate: tempFilter.dateRange.startDate, endDate: Date())
                    } else {
                        tempFilter.dateRange = DateRangeFilter(startDate: tempFilter.dateRange.startDate, endDate: nil)
                    }
                }
            ))
        }
    }
    
    // MARK: - Category Section
    private var categorySection: some View {
        Section("Categories") {
            ForEach(predefinedCategories, id: \.self) { category in
                FilterToggleRow(
                    title: category,
                    icon: "folder",
                    isOn: Binding(
                        get: { tempFilter.categories.contains(category) },
                        set: { isOn in
                            if isOn {
                                tempFilter.categories.insert(category)
                            } else {
                                tempFilter.categories.remove(category)
                            }
                        }
                    )
                )
            }
        }
    }
    
    // MARK: - Impact Score Section
    private var impactScoreSection: some View {
        Section("Impact Score Range") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Minimum: \(String(format: "%.1f", tempFilter.impactScore.minimumScore))")
                    Spacer()
                    Text("Maximum: \(String(format: "%.1f", tempFilter.impactScore.maximumScore))")
                }
                .font(.caption)
                .foregroundColor(.gray)
                
                RangeSlider(
                    range: Binding(
                        get: { tempFilter.impactScore.minimumScore...tempFilter.impactScore.maximumScore },
                        set: { newRange in
                            tempFilter.impactScore = ImpactScoreFilter(
                                minimumScore: newRange.lowerBound,
                                maximumScore: newRange.upperBound
                            )
                        }
                    ),
                    bounds: 0...10
                )
            }
        }
    }
    
    // MARK: - Author Section
    private var authorSection: some View {
        Section("Author Filters") {
            Toggle("Exclude My Content", isOn: $tempFilter.excludeOwnContent)
            
            // TODO: Add author selection interface
            Text("Selected Authors: \(tempFilter.authorUids.count)")
                .foregroundColor(.gray)
        }
    }
    
    // MARK: - Content Specific Section
    private var contentSpecificSection: some View {
        Section("Content Options") {
            FilterToggleRow(
                title: "Has Attachments",
                icon: "paperclip",
                isOn: Binding(
                    get: { tempFilter.hasAttachments == true },
                    set: { isOn in
                        tempFilter.hasAttachments = isOn ? true : nil
                    }
                )
            )
            
            FilterToggleRow(
                title: "Scheduled Messages",
                icon: "calendar",
                isOn: Binding(
                    get: { tempFilter.isScheduled == true },
                    set: { isOn in
                        tempFilter.isScheduled = isOn ? true : nil
                    }
                )
            )
            
            Toggle("Include Archived", isOn: $tempFilter.includeArchived)
            Toggle("Include Drafts", isOn: $tempFilter.includeDrafts)
        }
    }
    
    // MARK: - Sort Section
    private var sortSection: some View {
        Section("Sort Options") {
            Picker("Sort By", selection: $tempFilter.sortBy) {
                ForEach(SearchSortOption.allCases, id: \.self) { option in
                    Text(option.displayName).tag(option)
                }
            }
            
            Picker("Sort Order", selection: $tempFilter.sortOrder) {
                ForEach(SearchSortOrder.allCases, id: \.self) { order in
                    Text(order.displayName).tag(order)
                }
            }
        }
    }
    
    // MARK: - Reset Section
    private var resetSection: some View {
        Section {
            Button("Reset All Filters") {
                tempFilter = SearchFilter()
            }
            .foregroundColor(.red)
            
            HStack {
                Text("Active Filters")
                Spacer()
                Text("\(tempFilter.activeFilterCount)")
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
        }
    }
    
    // MARK: - Helper Properties
    private var predefinedCategories: [String] {
        [
            "Birthday",
            "Thank You", 
            "Congratulations",
            "Get Well",
            "Love & Romance",
            "Friendship",
            "Holiday",
            "Sympathy",
            "Motivation",
            "Business"
        ]
    }
    
    private func iconForType(_ type: SearchResultType) -> String {
        switch type {
        case .message: return "envelope"
        case .user: return "person.circle"
        case .template: return "doc.text"
        case .category: return "folder"
        }
    }
}

// MARK: - Filter Toggle Row
struct FilterToggleRow: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(title)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
    }
}

// MARK: - Range Slider Component
struct RangeSlider: View {
    @Binding var range: ClosedRange<Double>
    let bounds: ClosedRange<Double>
    
    @State private var lowerValue: Double = 0
    @State private var upperValue: Double = 10
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Track
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 4)
                    .cornerRadius(2)
                
                // Active track
                Rectangle()
                    .fill(Color.blue)
                    .frame(height: 4)
                    .cornerRadius(2)
                    .mask(
                        HStack {
                            Spacer()
                                .frame(width: CGFloat((lowerValue - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound)) * 200)
                            
                            Rectangle()
                                .frame(width: CGFloat((upperValue - lowerValue) / (bounds.upperBound - bounds.lowerBound)) * 200)
                            
                            Spacer()
                        }
                    )
                
                // Lower thumb
                Circle()
                    .fill(Color.blue)
                    .frame(width: 20, height: 20)
                    .offset(x: CGFloat((lowerValue - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound)) * 200 - 100)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newValue = bounds.lowerBound + (Double(value.location.x + 100) / 200.0) * (bounds.upperBound - bounds.lowerBound)
                                lowerValue = min(max(newValue, bounds.lowerBound), upperValue - 0.1)
                                updateRange()
                            }
                    )
                
                // Upper thumb
                Circle()
                    .fill(Color.blue)
                    .frame(width: 20, height: 20)
                    .offset(x: CGFloat((upperValue - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound)) * 200 - 100)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newValue = bounds.lowerBound + (Double(value.location.x + 100) / 200.0) * (bounds.upperBound - bounds.lowerBound)
                                upperValue = min(max(newValue, lowerValue + 0.1), bounds.upperBound)
                                updateRange()
                            }
                    )
            }
            .frame(width: 200, height: 20)
        }
        .onAppear {
            lowerValue = range.lowerBound
            upperValue = range.upperBound
        }
    }
    
    private func updateRange() {
        range = lowerValue...upperValue
    }
}

// MARK: - Filter Presets View
struct FilterPresetsView: View {
    @Binding var filter: SearchFilter
    let onSelectPreset: (SearchFilter) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Filters")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                presetButton("Recent Messages", preset: .recentMessages)
                presetButton("My Content", preset: .myContent)
                presetButton("Templates", preset: .templates)
                presetButton("Users", preset: .users)
                presetButton("Scheduled", preset: .scheduledContent)
            }
        }
        .padding()
    }
    
    private func presetButton(_ title: String, preset: SearchFilter) -> some View {
        Button(action: {
            onSelectPreset(preset)
        }) {
            VStack {
                Image(systemName: iconForPreset(title))
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
    
    private func iconForPreset(_ title: String) -> String {
        switch title {
        case "Recent Messages": return "clock"
        case "My Content": return "person.circle"
        case "Templates": return "doc.text"
        case "Users": return "person.2"
        case "Scheduled": return "calendar"
        default: return "folder"
        }
    }
}

// MARK: - Search History View
struct SearchHistoryView: View {
    @ObservedObject var searchHistory: SearchHistory
    let onSelectHistory: (SearchHistoryEntry) -> Void
    let onClearHistory: () -> Void
    
    @Environment(\.presentationMode) var presentationMode
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack {
                if filteredEntries.isEmpty {
                    emptyHistoryView
                } else {
                    historyList
                }
            }
            .navigationTitle("Search History")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Clear") {
                    onClearHistory()
                }
                .foregroundColor(.red)
            )
            .searchable(text: $searchText, prompt: "Search history...")
        }
    }
    
    private var filteredEntries: [SearchHistoryEntry] {
        if searchText.isEmpty {
            return searchHistory.entries
        } else {
            return searchHistory.searchHistory(query: searchText)
        }
    }
    
    private var historyList: some View {
        List {
            ForEach(filteredEntries) { entry in
                SearchHistoryRow(
                    entry: entry,
                    onTap: {
                        onSelectHistory(entry)
                    }
                )
            }
            .onDelete { indexSet in
                // Handle deletion
                for index in indexSet {
                    let entry = filteredEntries[index]
                    searchHistory.removeEntry(entry, for: entry.userUid)
                }
            }
        }
    }
    
    private var emptyHistoryView: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Search History")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Your search history will appear here")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Search History Row
struct SearchHistoryRow: View {
    let entry: SearchHistoryEntry
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.query)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    HStack {
                        Text("\(entry.resultCount) results")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        if entry.hasFilters {
                            Text("• Filtered")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        Text(entry.formattedTimestamp)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                Image(systemName: "arrow.up.left")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
struct SearchFiltersView_Previews: PreviewProvider {
    @State static var filter = SearchFilter()
    
    static var previews: some View {
        SearchFiltersView(filter: $filter) { _ in }
    }
}