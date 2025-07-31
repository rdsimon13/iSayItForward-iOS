import SwiftUI

struct CategoryDetailView: View {
    let category: Category
    @StateObject private var feedViewModel = CategoryFeedViewModel()
    @StateObject private var categoryService = CategoryService()
    @State private var isSubscribed = false
    @State private var showingSubscriptionOptions = false
    @State private var showingShareSheet = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header section
                headerSection
                
                // Statistics section
                statisticsSection
                
                // Content section
                contentSection
            }
        }
        .background(Color.mainAppGradient.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    subscriptionButton
                    shareButton
                    reportButton
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.brandYellow)
                }
            }
        }
        .sheet(isPresented: $showingSubscriptionOptions) {
            SubscriptionOptionsView(category: category, isSubscribed: $isSubscribed)
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareCategoryView(category: category)
        }
        .onAppear {
            loadCategoryData()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 20) {
            // Category icon and basic info
            VStack(spacing: 16) {
                // Icon
                Image(systemName: category.iconName)
                    .font(.system(size: 50))
                    .foregroundColor(CategoryUtilities.hexToColor(category.colorHex))
                    .frame(width: 80, height: 80)
                    .background(
                        Circle()
                            .fill(CategoryUtilities.hexToColor(category.colorHex).opacity(0.2))
                    )
                
                // Title and description
                VStack(spacing: 8) {
                    Text(category.displayName)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(category.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Category badges
                HStack(spacing: 12) {
                    if category.isSystem {
                        CategoryBadge(
                            icon: "checkmark.seal.fill",
                            text: "System",
                            color: .blue
                        )
                    }
                    
                    if category.lastUsedDate != nil {
                        CategoryBadge(
                            icon: "clock.fill",
                            text: "Active",
                            color: .green
                        )
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.white.opacity(0.9))
                    .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
            )
        }
        .padding()
    }
    
    // MARK: - Statistics Section
    private var statisticsSection: some View {
        VStack(spacing: 16) {
            Text("Category Statistics")
                .font(.headline)
                .padding(.horizontal)
            
            HStack(spacing: 20) {
                StatisticCard(
                    title: "Messages",
                    value: CategoryUtilities.formatUsageCount(category.messageCount),
                    icon: "envelope.fill",
                    color: .blue
                )
                
                StatisticCard(
                    title: "Subscribers",
                    value: CategoryUtilities.formatUsageCount(category.subscriberCount),
                    icon: "person.2.fill",
                    color: .green
                )
                
                StatisticCard(
                    title: "Last Used",
                    value: lastUsedText,
                    icon: "clock.fill",
                    color: .orange
                )
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
    
    // MARK: - Content Section
    private var contentSection: some View {
        VStack(spacing: 20) {
            // Messages in this category
            messagesSection
            
            // Related categories
            relatedCategoriesSection
            
            // Popular tags in this category
            popularTagsSection
        }
        .padding()
    }
    
    // MARK: - Messages Section
    private var messagesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Messages")
                    .font(.headline)
                
                Spacer()
                
                NavigationLink(destination: CategoryFeedView(category: category)) {
                    Text("View All")
                        .font(.caption)
                        .foregroundColor(.brandYellow)
                }
            }
            
            if feedViewModel.isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading messages...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else if feedViewModel.filteredMessages.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "envelope.badge")
                        .font(.title)
                        .foregroundColor(.gray)
                    
                    Text("No messages in this category yet")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.white.opacity(0.6))
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(Array(feedViewModel.filteredMessages.prefix(3)), id: \.id) { message in
                        MessagePreviewCard(message: message)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.8))
        )
    }
    
    // MARK: - Related Categories Section
    private var relatedCategoriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Related Categories")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(feedViewModel.getRelatedCategories().prefix(5), id: \.id) { relatedCategory in
                        NavigationLink(destination: CategoryDetailView(category: relatedCategory)) {
                            RelatedCategoryCard(category: relatedCategory)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.8))
        )
    }
    
    // MARK: - Popular Tags Section
    private var popularTagsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Popular Tags")
                .font(.headline)
            
            TagCloudView(
                onTagSelected: { tag in
                    // Navigate to tag-based feed or filter
                    print("Selected tag: \(tag.name)")
                },
                allowMultipleSelection: false,
                maxSelections: 1
            )
            .frame(height: 200)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.8))
        )
    }
    
    // MARK: - Toolbar Buttons
    private var subscriptionButton: some View {
        Button {
            showingSubscriptionOptions = true
        } label: {
            Label(
                isSubscribed ? "Manage Subscription" : "Subscribe",
                systemImage: isSubscribed ? "bell.fill" : "bell"
            )
        }
    }
    
    private var shareButton: some View {
        Button {
            showingShareSheet = true
        } label: {
            Label("Share Category", systemImage: "square.and.arrow.up")
        }
    }
    
    private var reportButton: some View {
        Button {
            // Handle report action
        } label: {
            Label("Report", systemImage: "exclamationmark.triangle")
        }
    }
    
    // MARK: - Computed Properties
    private var lastUsedText: String {
        if let lastUsed = category.lastUsedDate {
            return CategoryUtilities.formatRelativeDate(lastUsed)
        } else {
            return "Never"
        }
    }
    
    // MARK: - Actions
    private func loadCategoryData() {
        feedViewModel.selectCategory(category)
        checkSubscriptionStatus()
    }
    
    private func checkSubscriptionStatus() {
        // This would typically check if the user is subscribed to this category
        Task {
            // Placeholder implementation
            isSubscribed = false
        }
    }
}

// MARK: - Supporting Views

struct CategoryBadge: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(color.opacity(0.15))
        )
    }
}

struct StatisticCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.9))
        )
    }
}

struct MessagePreviewCard: View {
    let message: SIFItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(message.subject)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(1)
            
            Text(message.message)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack {
                Text(CategoryUtilities.formatRelativeDate(message.createdDate))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if !message.tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(Array(message.tags.prefix(2)), id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption2)
                                .foregroundColor(.brandYellow)
                        }
                        
                        if message.tags.count > 2 {
                            Text("+\(message.tags.count - 2)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.white.opacity(0.8))
        )
    }
}

struct RelatedCategoryCard: View {
    let category: Category
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: category.iconName)
                .font(.title2)
                .foregroundColor(CategoryUtilities.hexToColor(category.colorHex))
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(CategoryUtilities.hexToColor(category.colorHex).opacity(0.2))
                )
            
            Text(category.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
        }
        .padding()
        .frame(width: 80)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.9))
        )
    }
}

// MARK: - Additional Views (Stubs)
struct SubscriptionOptionsView: View {
    let category: Category
    @Binding var isSubscribed: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Subscription options for \(category.displayName)")
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ShareCategoryView: View {
    let category: Category
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Share \(category.displayName) category")
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Share")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct CategoryFeedView: View {
    let category: Category
    
    var body: some View {
        Text("Category Feed for \(category.displayName)")
            .navigationTitle(category.displayName)
    }
}

// MARK: - Preview
struct CategoryDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CategoryDetailView(category: Category.systemCategories[0])
        }
    }
}