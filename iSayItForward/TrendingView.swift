import SwiftUI

// MARK: - Trending View
struct TrendingView: View {
    @StateObject private var viewModel = TrendingViewModel()
    @State private var selectedTimeframe: TrendingTimeframe = .day
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Header
                trendingHeader
                
                // Timeframe Picker
                timeframePicker
                
                // Trending Topics
                if !viewModel.trendingTopics.isEmpty {
                    trendingTopicsSection
                }
                
                // Popular Categories
                popularCategoriesSection
                
                // Featured Users
                if !viewModel.featuredUsers.isEmpty {
                    featuredUsersSection
                }
                
                // Recommended Content
                if !viewModel.recommendedContent.isEmpty {
                    recommendedContentSection
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
        }
        .refreshable {
            await viewModel.refreshTrendingData()
        }
        .onAppear {
            viewModel.loadTrendingData(for: selectedTimeframe)
        }
        .onChange(of: selectedTimeframe) { timeframe in
            viewModel.loadTrendingData(for: timeframe)
        }
    }
    
    // MARK: - Header
    private var trendingHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Discover")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Trending content and popular searches")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Timeframe Picker
    private var timeframePicker: some View {
        Picker("Timeframe", selection: $selectedTimeframe) {
            ForEach(TrendingTimeframe.allCases, id: \.self) { timeframe in
                Text(timeframe.displayName).tag(timeframe)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
    }
    
    // MARK: - Trending Topics Section
    private var trendingTopicsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Trending Now", icon: "flame.fill", color: .orange)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(Array(viewModel.trendingTopics.prefix(6).enumerated()), id: \.element.id) { index, topic in
                    TrendingTopicCard(topic: topic, rank: index + 1)
                }
            }
            
            if viewModel.trendingTopics.count > 6 {
                Button("View All Trending") {
                    // TODO: Navigate to full trending list
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
    }
    
    // MARK: - Popular Categories Section
    private var popularCategoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Popular Categories", icon: "folder.fill", color: .purple)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(viewModel.popularCategories.prefix(6), id: \.id) { category in
                    PopularCategoryCard(category: category)
                }
            }
        }
    }
    
    // MARK: - Featured Users Section
    private var featuredUsersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Featured Users", icon: "star.fill", color: .yellow)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.featuredUsers.prefix(8), id: \.id) { user in
                        FeaturedUserCard(user: user)
                    }
                    
                    Spacer(minLength: 16)
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    // MARK: - Recommended Content Section
    private var recommendedContentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Recommended for You", icon: "heart.fill", color: .red)
            
            LazyVStack(spacing: 12) {
                ForEach(viewModel.recommendedContent.prefix(5), id: \.id) { content in
                    RecommendedContentCard(content: content)
                }
            }
        }
    }
    
    // MARK: - Section Header
    private func sectionHeader(_ title: String, icon: String, color: Color) -> some View {
        HStack {
            Label {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            } icon: {
                Image(systemName: icon)
                    .foregroundColor(color)
            }
            
            Spacer()
        }
    }
}

// MARK: - Trending Topic Card
struct TrendingTopicCard: View {
    let topic: TrendingTopic
    let rank: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("#\(rank)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                
                Spacer()
                
                Text(topic.trendIndicator.symbol)
                    .font(.caption)
                    .foregroundColor(Color(topic.trendIndicator.color))
            }
            
            Text(topic.name)
                .font(.headline)
                .fontWeight(.medium)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            if let description = topic.description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            
            HStack {
                Text(topic.formattedSearchCount)
                    .font(.caption2)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text(topic.category)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .clipShape(Capsule())
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
    }
}

// MARK: - Popular Category Card
struct PopularCategoryCard: View {
    let category: PopularCategory
    
    var body: some View {
        Button(action: {
            // TODO: Navigate to category search
        }) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(categoryColor.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: category.iconName ?? "folder.fill")
                        .font(.title2)
                        .foregroundColor(categoryColor)
                }
                
                Text(category.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Text(category.formattedMessageCount)
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    Text(category.trendDirection.symbol)
                        .font(.caption2)
                        .foregroundColor(Color(category.trendDirection.color))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
    
    private var categoryColor: Color {
        if let colorString = category.color {
            switch colorString {
            case "purple": return .purple
            case "red": return .red
            case "blue": return .blue
            case "green": return .green
            case "orange": return .orange
            default: return .blue
            }
        }
        return .blue
    }
}

// MARK: - Featured User Card
struct FeaturedUserCard: View {
    let user: FeaturedUser
    
    var body: some View {
        Button(action: {
            // TODO: Navigate to user profile
        }) {
            VStack(spacing: 8) {
                // Avatar
                AsyncImage(url: URL(string: user.profileImageUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.green)
                        )
                }
                .frame(width: 60, height: 60)
                .clipShape(Circle())
                
                VStack(spacing: 4) {
                    HStack {
                        Text(user.name)
                            .font(.caption)
                            .fontWeight(.medium)
                            .lineLimit(1)
                        
                        if user.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Text(user.featuredReason)
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "envelope")
                        Text("\(user.messageCount)")
                    }
                    .font(.caption2)
                    .foregroundColor(.gray)
                }
            }
            .frame(width: 100)
            .padding(8)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
        }
    }
}

// MARK: - Recommended Content Card
struct RecommendedContentCard: View {
    let content: RecommendedContent
    
    var body: some View {
        Button(action: {
            // TODO: Navigate to content
        }) {
            HStack(spacing: 12) {
                // Thumbnail or Icon
                AsyncImage(url: URL(string: content.thumbnailUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(contentTypeColor.opacity(0.2))
                        .overlay(
                            Image(systemName: iconForContentType)
                                .foregroundColor(contentTypeColor)
                                .font(.title2)
                        )
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                // Content Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(content.title)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    if let description = content.description {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(2)
                    }
                    
                    HStack {
                        if let authorName = content.authorName {
                            Text("by \(authorName)")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Text(content.category)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(contentTypeColor.opacity(0.2))
                            .foregroundColor(contentTypeColor)
                            .clipShape(Capsule())
                    }
                    
                    // Engagement metrics
                    HStack(spacing: 12) {
                        engagementMetric(icon: "eye", count: content.engagement.viewCount)
                        engagementMetric(icon: "heart", count: content.engagement.favoriteCount)
                        engagementMetric(icon: "square.and.arrow.up", count: content.engagement.shareCount)
                        
                        Spacer()
                        
                        Text(content.recommendationReason)
                            .font(.caption2)
                            .foregroundColor(.blue)
                            .italic()
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
        }
    }
    
    private var contentTypeColor: Color {
        switch content.contentType {
        case .message: return .blue
        case .user: return .green
        case .template: return .orange
        case .category: return .purple
        }
    }
    
    private var iconForContentType: String {
        switch content.contentType {
        case .message: return "envelope.fill"
        case .user: return "person.fill"
        case .template: return "doc.text.fill"
        case .category: return "folder.fill"
        }
    }
    
    private func engagementMetric(icon: String, count: Int) -> some View {
        HStack(spacing: 2) {
            Image(systemName: icon)
            Text("\(count)")
        }
        .font(.caption2)
        .foregroundColor(.gray)
    }
}

// MARK: - Trending View Model
class TrendingViewModel: ObservableObject {
    @Published var trendingTopics: [TrendingTopic] = []
    @Published var popularCategories: [PopularCategory] = []
    @Published var featuredUsers: [FeaturedUser] = []
    @Published var recommendedContent: [RecommendedContent] = []
    @Published var isLoading = false
    
    func loadTrendingData(for timeframe: TrendingTimeframe) {
        isLoading = true
        
        Task {
            // Simulate API call - in real app, this would fetch from Firebase
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            await MainActor.run {
                self.trendingTopics = TrendingTopic.mockData
                self.popularCategories = PopularCategory.mockData
                self.featuredUsers = generateMockFeaturedUsers()
                self.recommendedContent = generateMockRecommendedContent()
                self.isLoading = false
            }
        }
    }
    
    func refreshTrendingData() async {
        await loadTrendingData(for: .day)
    }
    
    private func generateMockFeaturedUsers() -> [FeaturedUser] {
        [
            FeaturedUser(
                id: "1",
                userUid: "user1",
                name: "Sarah Johnson",
                email: "sarah@example.com",
                profileImageUrl: nil,
                messageCount: 127,
                impactScore: 9.2,
                followerCount: 89,
                featuredReason: "Top contributor this week",
                category: "Motivation",
                joinDate: Date(),
                lastActive: Date(),
                isVerified: true
            ),
            FeaturedUser(
                id: "2",
                userUid: "user2",
                name: "Mike Chen",
                email: "mike@example.com",
                profileImageUrl: nil,
                messageCount: 95,
                impactScore: 8.7,
                followerCount: 64,
                featuredReason: "Most helpful responses",
                category: "Support",
                joinDate: Date(),
                lastActive: Date(),
                isVerified: false
            )
        ]
    }
    
    private func generateMockRecommendedContent() -> [RecommendedContent] {
        [
            RecommendedContent(
                id: "1",
                contentId: "content1",
                contentType: .template,
                title: "Heartfelt Birthday Wishes",
                description: "A beautiful template for birthday messages",
                thumbnailUrl: nil,
                authorName: "Sarah Johnson",
                category: "Celebrations",
                recommendationScore: 9.1,
                recommendationReason: "Popular in your network",
                createdDate: Date(),
                engagement: ContentEngagement(
                    viewCount: 1240,
                    shareCount: 89,
                    favoriteCount: 156,
                    commentCount: 23,
                    averageRating: 4.7
                )
            ),
            RecommendedContent(
                id: "2",
                contentId: "content2",
                contentType: .message,
                title: "Thank You for Your Support",
                description: "A touching message of gratitude",
                thumbnailUrl: nil,
                authorName: "Mike Chen",
                category: "Gratitude",
                recommendationScore: 8.8,
                recommendationReason: "Based on your interests",
                createdDate: Date(),
                engagement: ContentEngagement(
                    viewCount: 892,
                    shareCount: 67,
                    favoriteCount: 134,
                    commentCount: 18,
                    averageRating: 4.5
                )
            )
        ]
    }
}

// MARK: - Preview
struct TrendingView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TrendingView()
        }
    }
}