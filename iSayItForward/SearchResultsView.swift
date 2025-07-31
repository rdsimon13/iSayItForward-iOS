import SwiftUI

// MARK: - Search Results View
struct SearchResultsView: View {
    let results: [SearchResult]
    let onSelectResult: (SearchResult) -> Void
    
    @State private var selectedResultType: SearchResultType? = nil
    
    var body: some View {
        List {
            if !results.isEmpty {
                // Group results by type
                let groupedResults = Dictionary(grouping: results, by: \.type)
                
                ForEach(SearchResultType.allCases, id: \.self) { type in
                    if let typeResults = groupedResults[type], !typeResults.isEmpty {
                        Section(header: sectionHeader(for: type, count: typeResults.count)) {
                            ForEach(typeResults, id: \.id) { result in
                                SearchResultRow(
                                    result: result,
                                    onTap: {
                                        onSelectResult(result)
                                    }
                                )
                            }
                        }
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private func sectionHeader(for type: SearchResultType, count: Int) -> some View {
        HStack {
            Image(systemName: iconForType(type))
                .foregroundColor(.blue)
            
            Text(type.displayName)
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
            
            Text("\(count)")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.systemGray5))
                .clipShape(Capsule())
        }
        .padding(.vertical, 4)
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

// MARK: - Search Result Row
struct SearchResultRow: View {
    let result: SearchResult
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Result Icon
                resultIcon
                
                // Result Content
                VStack(alignment: .leading, spacing: 4) {
                    // Title
                    Text(result.title)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    // Subtitle
                    if let subtitle = result.subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    // Description
                    if let description = result.description {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    
                    // Metadata
                    resultMetadata
                }
                
                Spacer()
                
                // Relevance Score (if debugging)
                #if DEBUG
                VStack {
                    Text(String(format: "%.1f", result.score))
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
                #else
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.caption)
                #endif
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var resultIcon: some View {
        ZStack {
            Circle()
                .fill(iconBackgroundColor)
                .frame(width: 40, height: 40)
            
            Image(systemName: iconName)
                .foregroundColor(iconColor)
                .font(.system(size: 18, weight: .medium))
        }
    }
    
    private var iconName: String {
        switch result.type {
        case .message:
            return "envelope.fill"
        case .user:
            return "person.fill"
        case .template:
            return "doc.text.fill"
        case .category:
            return "folder.fill"
        }
    }
    
    private var iconColor: Color {
        switch result.type {
        case .message:
            return .blue
        case .user:
            return .green
        case .template:
            return .orange
        case .category:
            return .purple
        }
    }
    
    private var iconBackgroundColor: Color {
        iconColor.opacity(0.1)
    }
    
    private var resultMetadata: some View {
        HStack(spacing: 8) {
            // Type Badge
            Text(result.type.rawValue.capitalized)
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(iconColor.opacity(0.2))
                .foregroundColor(iconColor)
                .clipShape(Capsule())
            
            // Date
            Text(RelativeDateTimeFormatter().localizedString(for: result.lastModified, relativeTo: Date()))
                .font(.caption2)
                .foregroundColor(.gray)
            
            Spacer()
            
            // Additional metadata based on type
            additionalMetadata
        }
    }
    
    private var additionalMetadata: some View {
        Group {
            switch result.type {
            case .message:
                if let scheduledDate = result.scheduledDate {
                    Label {
                        Text(formatDate(scheduledDate))
                            .font(.caption2)
                    } icon: {
                        Image(systemName: "calendar")
                    }
                    .foregroundColor(.orange)
                }
                
            case .user:
                if let email = result.email {
                    Text(email)
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                
            case .template:
                if let categoryName = result.categoryName {
                    Label {
                        Text(categoryName)
                            .font(.caption2)
                    } icon: {
                        Image(systemName: "tag")
                    }
                    .foregroundColor(.purple)
                }
                
            case .category:
                EmptyView()
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Search Result Type Extension
extension SearchResultType {
    var displayName: String {
        switch self {
        case .message: return "Messages"
        case .user: return "Users"
        case .template: return "Templates"
        case .category: return "Categories"
        }
    }
}

// MARK: - Empty Results View
struct EmptySearchResultsView: View {
    let searchQuery: String
    let hasFilters: Bool
    let onClearFilters: () -> Void
    let onSearchSuggestions: ([String]) -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 80))
                .foregroundColor(.gray.opacity(0.5))
            
            // Message
            VStack(spacing: 8) {
                Text("No results found")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                if !searchQuery.isEmpty {
                    Text("No results for \"\(searchQuery)\"")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Suggestions
            VStack(spacing: 12) {
                Text("Try:")
                    .font(.headline)
                    .fontWeight(.medium)
                
                VStack(alignment: .leading, spacing: 8) {
                    suggestionRow(icon: "textformat.abc", text: "Different keywords or spelling")
                    suggestionRow(icon: "slider.horizontal.3", text: "Fewer or different filters")
                    suggestionRow(icon: "magnifyingglass", text: "More general search terms")
                }
            }
            
            // Actions
            VStack(spacing: 12) {
                if hasFilters {
                    Button("Clear All Filters") {
                        onClearFilters()
                    }
                    .buttonStyle(PrimaryActionButtonStyle())
                }
                
                Button("Search Suggestions") {
                    let suggestions = generateSuggestions(for: searchQuery)
                    onSearchSuggestions(suggestions)
                }
                .buttonStyle(SecondaryActionButtonStyle())
            }
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func suggestionRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.caption)
                .frame(width: 16)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.gray)
            
            Spacer()
        }
    }
    
    private func generateSuggestions(for query: String) -> [String] {
        let baseSuggestions = [
            "birthday wishes",
            "thank you",
            "congratulations",
            "get well soon",
            "anniversary"
        ]
        
        // If query is not empty, try to find related suggestions
        if !query.isEmpty {
            let relatedSuggestions = baseSuggestions.filter { suggestion in
                suggestion.localizedCaseInsensitiveContains(query) ||
                query.localizedCaseInsensitiveContains(suggestion)
            }
            
            return relatedSuggestions.isEmpty ? baseSuggestions : relatedSuggestions
        }
        
        return baseSuggestions
    }
}

// MARK: - Search Result Detail Views
struct MessageResultDetailView: View {
    let result: SearchResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(result.title)
                .font(.title2)
                .fontWeight(.bold)
            
            if let description = result.description {
                Text(description)
                    .font(.body)
            }
            
            if let scheduledDate = result.scheduledDate {
                Label {
                    Text("Scheduled for \(formatDate(scheduledDate))")
                } icon: {
                    Image(systemName: "calendar")
                }
                .foregroundColor(.orange)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Message Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct UserResultDetailView: View {
    let result: SearchResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.title)
                            .foregroundColor(.green)
                    )
                
                VStack(alignment: .leading) {
                    Text(result.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let email = result.email {
                        Text(email)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("User Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview
struct SearchResultsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SearchResultsView(
                results: mockSearchResults,
                onSelectResult: { _ in }
            )
        }
    }
    
    static var mockSearchResults: [SearchResult] {
        [
            SearchResult(
                id: "1",
                type: .message,
                title: "Happy Birthday!",
                subtitle: "Scheduled for tomorrow",
                description: "Wishing you a wonderful birthday filled with joy...",
                score: 5.0,
                lastModified: Date(),
                metadata: ["messageId": "1", "authorUid": "user1"]
            ),
            SearchResult(
                id: "2",
                type: .user,
                title: "John Doe",
                subtitle: "john.doe@example.com",
                description: nil,
                score: 4.2,
                lastModified: Date(),
                metadata: ["userUid": "user2", "email": "john.doe@example.com"]
            ),
            SearchResult(
                id: "3",
                type: .template,
                title: "Birthday Template",
                subtitle: "Celebrations",
                description: "A beautiful birthday message template...",
                score: 3.8,
                lastModified: Date(),
                metadata: ["templateId": "template1", "categoryName": "Celebrations"]
            )
        ]
    }
}