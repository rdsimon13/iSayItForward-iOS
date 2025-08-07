import SwiftUI

struct SIFStatisticsView: View {
    @ObservedObject var settingsManager: SIFSettingsManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color.mainAppGradient.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack {
                        Text("SIF Statistics")
                            .font(.largeTitle.weight(.bold))
                            .foregroundColor(.white)
                            .padding(.top)
                        
                        Text("Track your SIF activity and impact")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    // Overview Cards
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        StatCard(
                            title: "SIFs Sent",
                            value: "\(settingsManager.statistics.totalSIFsSent)",
                            iconName: "paperplane.fill",
                            color: Color.brandYellow
                        )
                        
                        StatCard(
                            title: "SIFs Scheduled",
                            value: "\(settingsManager.statistics.totalSIFsScheduled)",
                            iconName: "calendar.badge.plus",
                            color: Color.brandDarkBlue
                        )
                        
                        StatCard(
                            title: "Current Streak",
                            value: "\(settingsManager.statistics.currentStreak) days",
                            iconName: "flame.fill",
                            color: .orange
                        )
                        
                        StatCard(
                            title: "Impact Score",
                            value: String(format: "%.1f", settingsManager.statistics.impactScore),
                            iconName: "star.fill",
                            color: .purple
                        )
                    }
                    
                    // Detailed Statistics Section
                    StatisticsSectionView(title: "Activity Overview", iconName: "chart.bar") {
                        VStack(spacing: 16) {
                            StatRow(
                                title: "Total SIFs Sent",
                                value: "\(settingsManager.statistics.totalSIFsSent)",
                                iconName: "paperplane"
                            )
                            
                            StatRow(
                                title: "Total SIFs Scheduled",
                                value: "\(settingsManager.statistics.totalSIFsScheduled)",
                                iconName: "calendar"
                            )
                            
                            StatRow(
                                title: "Total SIFs Received",
                                value: "\(settingsManager.statistics.totalSIFsReceived)",
                                iconName: "tray.full"
                            )
                            
                            StatRow(
                                title: "Average Response Time",
                                value: formatResponseTime(settingsManager.statistics.averageResponseTime),
                                iconName: "clock"
                            )
                        }
                    }
                    
                    // Impact Metrics Section
                    StatisticsSectionView(title: "Impact Metrics", iconName: "heart.circle") {
                        VStack(spacing: 16) {
                            StatRow(
                                title: "Current Streak",
                                value: "\(settingsManager.statistics.currentStreak) days",
                                iconName: "flame"
                            )
                            
                            StatRow(
                                title: "Longest Streak",
                                value: "\(settingsManager.statistics.longestStreak) days",
                                iconName: "trophy"
                            )
                            
                            StatRow(
                                title: "Impact Score",
                                value: String(format: "%.1f", settingsManager.statistics.impactScore),
                                iconName: "star"
                            )
                            
                            if let template = settingsManager.statistics.mostUsedTemplate {
                                StatRow(
                                    title: "Most Used Template",
                                    value: template,
                                    iconName: "doc.badge.gearshape"
                                )
                            }
                        }
                    }
                    
                    // Activity Timeline Section
                    StatisticsSectionView(title: "Activity Timeline", iconName: "timeline.selection") {
                        VStack(spacing: 16) {
                            if let lastActivity = settingsManager.statistics.lastActivityDate {
                                StatRow(
                                    title: "Last Activity",
                                    value: formatDate(lastActivity),
                                    iconName: "clock.arrow.circlepath"
                                )
                            } else {
                                Text("No activity recorded yet")
                                    .font(.subheadline)
                                    .foregroundColor(Color.brandDarkBlue.opacity(0.7))
                                    .padding()
                            }
                            
                            // Activity level indicator
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Activity Level")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(Color.brandDarkBlue)
                                
                                ActivityLevelIndicator(
                                    totalActivity: settingsManager.statistics.totalSIFsSent + settingsManager.statistics.totalSIFsScheduled
                                )
                            }
                        }
                    }
                    
                    // Achievements Section
                    StatisticsSectionView(title: "Achievements", iconName: "rosette") {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            AchievementBadge(
                                title: "First SIF",
                                isEarned: settingsManager.statistics.totalSIFsSent > 0,
                                iconName: "1.circle.fill"
                            )
                            
                            AchievementBadge(
                                title: "Scheduler",
                                isEarned: settingsManager.statistics.totalSIFsScheduled > 0,
                                iconName: "calendar.circle.fill"
                            )
                            
                            AchievementBadge(
                                title: "Streak Master",
                                isEarned: settingsManager.statistics.longestStreak >= 7,
                                iconName: "flame.circle.fill"
                            )
                            
                            AchievementBadge(
                                title: "Active User",
                                isEarned: settingsManager.statistics.totalSIFsSent >= 10,
                                iconName: "star.circle.fill"
                            )
                            
                            AchievementBadge(
                                title: "Super User",
                                isEarned: settingsManager.statistics.totalSIFsSent >= 50,
                                iconName: "crown.fill"
                            )
                            
                            AchievementBadge(
                                title: "Impact Maker",
                                isEarned: settingsManager.statistics.impactScore >= 100,
                                iconName: "heart.circle.fill"
                            )
                        }
                    }
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            settingsManager.loadSettings()
        }
    }
    
    private func formatResponseTime(_ hours: Double) -> String {
        if hours < 1 {
            return "\(Int(hours * 60))m"
        } else if hours < 24 {
            return String(format: "%.1fh", hours)
        } else {
            return String(format: "%.1fd", hours / 24)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views
private struct StatCard: View {
    let title: String
    let value: String
    let iconName: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundColor(Color.brandDarkBlue)
            
            Text(title)
                .font(.caption)
                .foregroundColor(Color.brandDarkBlue.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.white.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 3, y: 1)
    }
}

private struct StatisticsSectionView<Content: View>: View {
    let title: String
    let iconName: String
    let content: Content
    
    init(title: String, iconName: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.iconName = iconName
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: iconName)
                    .foregroundColor(Color.brandDarkBlue)
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundColor(Color.brandDarkBlue)
                Spacer()
            }
            
            content
        }
        .padding(20)
        .background(.white.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
    }
}

private struct StatRow: View {
    let title: String
    let value: String
    let iconName: String
    
    var body: some View {
        HStack {
            Image(systemName: iconName)
                .frame(width: 20)
                .foregroundColor(Color.brandDarkBlue.opacity(0.7))
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(Color.brandDarkBlue)
            
            Spacer()
            
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundColor(Color.brandDarkBlue)
        }
    }
}

private struct ActivityLevelIndicator: View {
    let totalActivity: Int
    
    private var activityLevel: String {
        switch totalActivity {
        case 0:
            return "Getting Started"
        case 1...5:
            return "Beginner"
        case 6...15:
            return "Active"
        case 16...30:
            return "Regular"
        case 31...50:
            return "Expert"
        default:
            return "Master"
        }
    }
    
    private var progressValue: Double {
        let level = min(totalActivity, 50)
        return Double(level) / 50.0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(activityLevel)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(Color.brandDarkBlue)
                Spacer()
                Text("\(totalActivity)/50")
                    .font(.caption)
                    .foregroundColor(Color.brandDarkBlue.opacity(0.7))
            }
            
            ProgressView(value: progressValue)
                .progressViewStyle(LinearProgressViewStyle(tint: Color.brandYellow))
                .scaleEffect(x: 1, y: 1.5, anchor: .center)
        }
    }
}

private struct AchievementBadge: View {
    let title: String
    let isEarned: Bool
    let iconName: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(isEarned ? Color.brandYellow : Color.gray.opacity(0.4))
            
            Text(title)
                .font(.caption2)
                .foregroundColor(isEarned ? Color.brandDarkBlue : Color.gray.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(isEarned ? .white.opacity(0.9) : .white.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isEarned ? Color.brandYellow.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}

struct SIFStatisticsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SIFStatisticsView(settingsManager: SIFSettingsManager())
        }
    }
}