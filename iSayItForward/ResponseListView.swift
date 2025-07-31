import SwiftUI

/// View for displaying list of responses with signatures
struct ResponseListView: View {
    let sifId: String?
    
    @StateObject private var responseManager = ResponseManager()
    @StateObject private var signatureService = SignatureService()
    
    @State private var selectedFilter: ResponseFilter = .all
    @State private var showingFilterOptions = false
    @State private var searchText = ""
    @State private var selectedResponse: ResponseModel?
    @State private var showingResponseDetails = false
    @State private var showingComposeResponse = false
    
    enum ResponseFilter: String, CaseIterable {
        case all = "all"
        case signed = "signed"
        case unsigned = "unsigned"
        case myResponses = "my_responses"
        
        var displayName: String {
            switch self {
            case .all:
                return "All Responses"
            case .signed:
                return "With Signatures"
            case .unsigned:
                return "Without Signatures"
            case .myResponses:
                return "My Responses"
            }
        }
        
        var iconName: String {
            switch self {
            case .all:
                return "list.bullet"
            case .signed:
                return "signature"
            case .unsigned:
                return "doc.text"
            case .myResponses:
                return "person.circle"
            }
        }
    }
    
    var filteredResponses: [ResponseModel] {
        var responses = responseManager.responses
        
        // Apply search filter
        if !searchText.isEmpty {
            responses = responses.filter { response in
                response.responseText.localizedCaseInsensitiveContains(searchText) ||
                response.category.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply category filter
        switch selectedFilter {
        case .all:
            break
        case .signed:
            responses = responses.filter { $0.isSignatureValid }
        case .unsigned:
            responses = responses.filter { !$0.requiresSignature || !$0.isSignatureValid }
        case .myResponses:
            // This would filter by current user - placeholder for now
            break
        }
        
        return responses
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and Filter Section
                searchAndFilterSection
                
                if responseManager.isLoading {
                    loadingView
                } else if filteredResponses.isEmpty {
                    emptyStateView
                } else {
                    // Responses List
                    responsesList
                }
            }
            .navigationTitle(sifId != nil ? "Responses" : "All Responses")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if sifId != nil {
                        Button(action: {
                            showingComposeResponse = true
                        }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .refreshable {
                await loadResponses()
            }
            .task {
                await loadResponses()
            }
        }
        .sheet(isPresented: $showingResponseDetails) {
            if let response = selectedResponse {
                ResponseDetailView(response: response)
            }
        }
        .sheet(isPresented: $showingComposeResponse) {
            if let sifId = sifId {
                // This would need the actual SIFItem - placeholder for now
                Text("Compose Response View would go here")
            }
        }
    }
    
    // MARK: - Search and Filter
    
    private var searchAndFilterSection: some View {
        VStack(spacing: 12) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search responses...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            // Filter Options
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ResponseFilter.allCases, id: \.self) { filter in
                        FilterChip(
                            title: filter.displayName,
                            icon: filter.iconName,
                            isSelected: selectedFilter == filter,
                            action: {
                                selectedFilter = filter
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.3))
    }
    
    // MARK: - Responses List
    
    private var responsesList: some View {
        List {
            ForEach(filteredResponses) { response in
                ResponseRowView(
                    response: response,
                    onTap: {
                        selectedResponse = response
                        showingResponseDetails = true
                    }
                )
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(PlainListStyle())
    }
    
    // MARK: - Supporting Views
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading responses...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: filteredResponses.isEmpty && !searchText.isEmpty ? "magnifyingglass" : "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            Text(emptyStateTitle)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(emptyStateMessage)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if sifId != nil && filteredResponses.isEmpty && searchText.isEmpty {
                Button("Add First Response") {
                    showingComposeResponse = true
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var emptyStateTitle: String {
        if !searchText.isEmpty {
            return "No Results Found"
        } else if selectedFilter != .all {
            return "No \(selectedFilter.displayName)"
        } else {
            return "No Responses Yet"
        }
    }
    
    private var emptyStateMessage: String {
        if !searchText.isEmpty {
            return "Try adjusting your search terms or filters."
        } else if selectedFilter != .all {
            return "There are no responses matching the selected filter."
        } else {
            return "Responses to this SIF will appear here once people start responding."
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadResponses() async {
        if let sifId = sifId {
            await responseManager.loadResponsesForSIF(sifId)
        } else {
            await responseManager.loadUserResponses()
        }
    }
}

// MARK: - Supporting Views

struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.blue : Color(.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
        }
    }
}

struct ResponseRowView: View {
    let response: ResponseModel
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with category and privacy
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: response.category.iconName)
                            .foregroundColor(.blue)
                        
                        Text(response.category.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        if response.isSignatureValid {
                            Image(systemName: "signature")
                                .foregroundColor(.green)
                                .font(.caption)
                        }
                        
                        Image(systemName: privacyIcon(for: response.privacyLevel))
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                
                // Response content
                Text(response.responseText)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                
                // Footer with date and stats
                HStack {
                    Text(formatDate(response.createdDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if let impactScore = response.impactScore {
                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                                .font(.caption)
                            
                            Text("\(Int(impactScore * 100))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func privacyIcon(for privacy: PrivacyLevel) -> String {
        switch privacy {
        case .public:
            return "globe"
        case .private:
            return "lock"
        case .restricted:
            return "lock.shield"
        case .anonymous:
            return "person.fill.questionmark"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Response Detail View

struct ResponseDetailView: View {
    let response: ResponseModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Response Content
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Response")
                            .font(.headline)
                        
                        Text(response.responseText)
                            .font(.body)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    
                    // Metadata
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Details")
                            .font(.headline)
                        
                        VStack(spacing: 8) {
                            DetailRow(title: "Category", value: response.category.displayName)
                            DetailRow(title: "Privacy", value: response.privacyLevel.displayName)
                            DetailRow(title: "Created", value: formatDate(response.createdDate))
                            
                            if response.isSignatureValid {
                                DetailRow(title: "Signature", value: "Verified ✓")
                            }
                            
                            if let impactScore = response.impactScore {
                                DetailRow(title: "Impact Score", value: "\(Int(impactScore * 100))%")
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Response Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Dismiss view
                    }
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Preview
struct ResponseListView_Previews: PreviewProvider {
    static var previews: some View {
        ResponseListView(sifId: "sample-sif-id")
    }
}