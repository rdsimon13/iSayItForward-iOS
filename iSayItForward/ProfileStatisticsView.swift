import SwiftUI

struct ProfileStatisticsView: View {
    let statistics: [StatisticItem]
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Impact Statistics")
                .font(.headline.weight(.bold))
                .foregroundColor(Color.brandDarkBlue)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: gridColumns, spacing: 12) {
                ForEach(statistics) { stat in
                    StatisticCard(item: stat)
                }
            }
        }
        .padding()
        .background(.white.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
    }
    
    private var gridColumns: [GridItem] {
        [
            GridItem(.flexible()),
            GridItem(.flexible())
        ]
    }
}

struct StatisticCard: View {
    let item: StatisticItem
    
    var body: some View {
        VStack(spacing: 8) {
            // Icon
            Image(systemName: item.icon)
                .font(.title2)
                .foregroundColor(Color.brandYellow)
                .frame(width: 40, height: 40)
                .background(Color.brandYellow.opacity(0.2))
                .clipShape(Circle())
            
            // Value
            Text(item.value)
                .font(.title3.weight(.bold))
                .foregroundColor(Color.brandDarkBlue)
            
            // Title
            Text(item.title)
                .font(.caption)
                .foregroundColor(Color.brandDarkBlue.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(Color.brandDarkBlue.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Extended Statistics View

struct DetailedStatisticsView: View {
    let profile: UserProfile
    
    var body: some View {
        VStack(spacing: 20) {
            // Main statistics grid
            ProfileStatisticsView(statistics: mainStatistics)
            
            // Additional metrics
            AdditionalMetricsView(profile: profile)
        }
    }
    
    private var mainStatistics: [StatisticItem] {
        [
            StatisticItem(title: "SIFs Shared", value: "\(profile.sifsSharedCount)", icon: "envelope.fill"),
            StatisticItem(title: "Followers", value: "\(profile.followersCount)", icon: "person.2.fill"),
            StatisticItem(title: "Following", value: "\(profile.followingCount)", icon: "person.fill.badge.plus"),
            StatisticItem(title: "Impact Score", value: "\(profile.totalImpactScore)", icon: "heart.fill")
        ]
    }
}

struct AdditionalMetricsView: View {
    let profile: UserProfile
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Community Impact")
                .font(.headline.weight(.bold))
                .foregroundColor(Color.brandDarkBlue)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 8) {
                MetricRow(
                    title: "Engagement Rate",
                    value: engagementRate,
                    icon: "chart.line.uptrend.xyaxis"
                )
                
                MetricRow(
                    title: "Average Impact per SIF",
                    value: averageImpact,
                    icon: "target"
                )
                
                MetricRow(
                    title: "Community Rank",
                    value: communityRank,
                    icon: "trophy.fill"
                )
            }
        }
        .padding()
        .background(.white.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
    }
    
    private var engagementRate: String {
        let rate = profile.followersCount > 0 ? 
            Double(profile.totalImpactScore) / Double(profile.followersCount) : 0.0
        return String(format: "%.1f%%", min(rate, 100.0))
    }
    
    private var averageImpact: String {
        let average = profile.sifsSharedCount > 0 ? 
            Double(profile.totalImpactScore) / Double(profile.sifsSharedCount) : 0.0
        return String(format: "%.1f", average)
    }
    
    private var communityRank: String {
        // Simple ranking based on impact score
        switch profile.totalImpactScore {
        case 0..<100:
            return "Newcomer"
        case 100..<500:
            return "Rising Star"
        case 500..<1000:
            return "Influencer"
        case 1000..<2500:
            return "Community Leader"
        default:
            return "Impact Champion"
        }
    }
}

struct MetricRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(Color.brandYellow)
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(Color.brandDarkBlue)
            
            Spacer()
            
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Color.brandDarkBlue)
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Preview

struct ProfileStatisticsView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 20) {
                ProfileStatisticsView(statistics: sampleStatistics)
                
                DetailedStatisticsView(profile: sampleProfile)
            }
            .padding()
        }
        .background(Color.mainAppGradient)
        .preferredColorScheme(.light)
    }
    
    static let sampleStatistics = [
        StatisticItem(title: "SIFs Shared", value: "156", icon: "envelope.fill"),
        StatisticItem(title: "Followers", value: "42", icon: "person.2.fill"),
        StatisticItem(title: "Following", value: "28", icon: "person.fill.badge.plus"),
        StatisticItem(title: "Impact Score", value: "2,340", icon: "heart.fill")
    ]
    
    static let sampleProfile = UserProfile(
        uid: "123",
        name: "John Doe",
        email: "john@example.com",
        bio: "Spreading kindness one SIF at a time!",
        profileImageURL: nil,
        joinDate: Date(),
        followersCount: 42,
        followingCount: 28,
        sifsSharedCount: 156,
        totalImpactScore: 2340
    )
}