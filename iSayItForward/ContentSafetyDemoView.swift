import SwiftUI

/// Demo view to showcase Content Safety & Reporting System features
/// This view demonstrates all implemented functionality for testing and presentation
struct ContentSafetyDemoView: View {
    @StateObject private var contentSafetyManager = ContentSafetyManager()
    
    @State private var selectedDemo: DemoSection = .overview
    @State private var showingReportView = false
    @State private var showingModeratorView = false
    @State private var showingBlockedUsersView = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.mainAppGradient.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Demo Section Picker
                    Picker("Demo Section", selection: $selectedDemo) {
                        ForEach(DemoSection.allCases, id: \.self) { section in
                            Text(section.title).tag(section)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    
                    // Demo Content
                    ScrollView {
                        VStack(spacing: 20) {
                            switch selectedDemo {
                            case .overview:
                                OverviewSection()
                            case .reporting:
                                ReportingSection(onShowReport: {
                                    showingReportView = true
                                })
                            case .moderation:
                                ModerationSection(onShowModeration: {
                                    showingModeratorView = true
                                })
                            case .blocking:
                                BlockingSection(onShowBlockedUsers: {
                                    showingBlockedUsersView = true
                                })
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Content Safety Demo")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingReportView) {
            ReportView(
                contentId: "demo-content-123",
                contentAuthorUid: "demo-author-456",
                onDismiss: { showingReportView = false }
            )
        }
        .sheet(isPresented: $showingModeratorView) {
            ModeratorView()
        }
        .sheet(isPresented: $showingBlockedUsersView) {
            BlockedUsersView()
        }
    }
}

// MARK: - Demo Sections

enum DemoSection: CaseIterable {
    case overview
    case reporting
    case moderation
    case blocking
    
    var title: String {
        switch self {
        case .overview: return "Overview"
        case .reporting: return "Reporting"
        case .moderation: return "Moderation"
        case .blocking: return "Blocking"
        }
    }
}

// MARK: - Overview Section

struct OverviewSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            FeatureCard(
                icon: "shield.checkered",
                title: "Content Safety System",
                description: "Complete system for reporting, moderating, and blocking inappropriate content and users."
            )
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Key Features Implemented:")
                    .font(.headline.weight(.bold))
                    .foregroundColor(.white)
                
                FeatureRow(icon: "flag.fill", text: "Content Reporting")
                FeatureRow(icon: "shield.fill", text: "Content Moderation")
                FeatureRow(icon: "person.badge.minus", text: "User Blocking")
                FeatureRow(icon: "eye.slash", text: "Content Filtering")
                FeatureRow(icon: "doc.text", text: "Report Management")
                FeatureRow(icon: "checkmark.shield", text: "Moderator Tools")
            }
            .padding()
            .background(.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Reporting Section

struct ReportingSection: View {
    let onShowReport: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            FeatureCard(
                icon: "flag.fill",
                title: "Content Reporting",
                description: "Users can report inappropriate content with detailed categories and descriptions."
            )
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Report Categories:")
                    .font(.headline.weight(.bold))
                    .foregroundColor(.white)
                
                ForEach(ReportCategory.allCases, id: \.self) { category in
                    CategoryDemo(category: category)
                }
            }
            .padding()
            .background(.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Button("Try Reporting Feature") {
                onShowReport()
            }
            .buttonStyle(PrimaryActionButtonStyle())
        }
    }
}

// MARK: - Moderation Section

struct ModerationSection: View {
    let onShowModeration: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            FeatureCard(
                icon: "shield.fill",
                title: "Content Moderation",
                description: "Moderators can review reports, take actions, and track status of reported content."
            )
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Moderator Actions:")
                    .font(.headline.weight(.bold))
                    .foregroundColor(.white)
                
                FeatureRow(icon: "eye", text: "Review reported content")
                FeatureRow(icon: "checkmark.circle", text: "Approve or dismiss reports")
                FeatureRow(icon: "xmark.circle", text: "Resolve violations")
                FeatureRow(icon: "note.text", text: "Add moderator notes")
                FeatureRow(icon: "clock", text: "Track report status")
            }
            .padding()
            .background(.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Button("Open Moderator Tools") {
                onShowModeration()
            }
            .buttonStyle(PrimaryActionButtonStyle())
        }
    }
}

// MARK: - Blocking Section

struct BlockingSection: View {
    let onShowBlockedUsers: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            FeatureCard(
                icon: "person.badge.minus",
                title: "User Blocking",
                description: "Users can block other users to prevent seeing their content and interactions."
            )
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Blocking Features:")
                    .font(.headline.weight(.bold))
                    .foregroundColor(.white)
                
                FeatureRow(icon: "person.badge.minus", text: "Block users from content")
                FeatureRow(icon: "eye.slash", text: "Filter out blocked content")
                FeatureRow(icon: "list.bullet", text: "Manage blocked users")
                FeatureRow(icon: "arrow.counterclockwise", text: "Unblock users anytime")
            }
            .padding()
            .background(.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Demonstrate content filtering
            VStack(alignment: .leading, spacing: 8) {
                Text("Content Filtering Demo:")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
                
                Text("Original content: \(ContentSafetyTestData.sampleSIFItems.count) items")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                Text("Filtered content: \(ContentSafetyTestData.getFilteredContent().count) items")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                Text("(\(ContentSafetyTestData.sampleSIFItems.count - ContentSafetyTestData.getFilteredContent().count) items from blocked users hidden)")
                    .font(.caption)
                    .foregroundColor(.orange.opacity(0.8))
            }
            .padding()
            .background(.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Button("Manage Blocked Users") {
                onShowBlockedUsers()
            }
            .buttonStyle(PrimaryActionButtonStyle())
        }
    }
}

// MARK: - Helper Components

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.title2.weight(.bold))
                    .foregroundColor(.white)
            }
            
            Text(description)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
        }
        .padding()
        .background(.white.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
        }
    }
}

struct CategoryDemo: View {
    let category: ReportCategory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(category.displayName)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.white)
            
            Text(category.description)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

struct ContentSafetyDemoView_Previews: PreviewProvider {
    static var previews: some View {
        ContentSafetyDemoView()
    }
}