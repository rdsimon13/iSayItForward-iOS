import SwiftUI
import FirebaseAuth

struct ModeratorView: View {
    @StateObject private var contentSafetyManager = ContentSafetyManager()
    
    @State private var selectedFilter: ReportStatusFilter = .pending
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    var filteredReports: [Report] {
        switch selectedFilter {
        case .all:
            return contentSafetyManager.reports
        case .pending:
            return contentSafetyManager.reports.filter { $0.status == .pending }
        case .underReview:
            return contentSafetyManager.reports.filter { $0.status == .underReview }
        case .resolved:
            return contentSafetyManager.reports.filter { $0.status == .resolved }
        case .dismissed:
            return contentSafetyManager.reports.filter { $0.status == .dismissed }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.mainAppGradient.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Filter Tabs
                    FilterTabsView(selectedFilter: $selectedFilter)
                        .padding()
                    
                    // Reports List
                    if contentSafetyManager.isLoading {
                        ProgressView("Loading reports...")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if filteredReports.isEmpty {
                        EmptyStateView(filter: selectedFilter)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredReports) { report in
                                    NavigationLink(destination: ReportDetailView(report: report)) {
                                        ReportRowView(report: report)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Content Moderation")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                Task {
                    await contentSafetyManager.fetchReports()
                }
            }
            .refreshable {
                await contentSafetyManager.fetchReports()
            }
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .onReceive(contentSafetyManager.$errorMessage) { error in
            if let error = error {
                errorMessage = error
                showingErrorAlert = true
            }
        }
    }
}

// MARK: - Report Status Filter

enum ReportStatusFilter: String, CaseIterable {
    case all = "all"
    case pending = "pending"
    case underReview = "under_review"
    case resolved = "resolved"
    case dismissed = "dismissed"
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .pending: return "Pending"
        case .underReview: return "Under Review"
        case .resolved: return "Resolved"
        case .dismissed: return "Dismissed"
        }
    }
    
    var count: Int {
        // This would ideally be computed from the actual data
        return 0
    }
}

// MARK: - Filter Tabs View

struct FilterTabsView: View {
    @Binding var selectedFilter: ReportStatusFilter
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ReportStatusFilter.allCases, id: \.self) { filter in
                    FilterTab(
                        title: filter.displayName,
                        isSelected: selectedFilter == filter
                    ) {
                        selectedFilter = filter
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Filter Tab Component

struct FilterTab: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundColor(isSelected ? Color.brandDarkBlue : .white.opacity(0.7))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? .white.opacity(0.9) : .white.opacity(0.2))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Report Row View

struct ReportRowView: View {
    let report: Report
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with category and status
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: categoryIcon)
                        .foregroundColor(Color.brandDarkBlue)
                    Text(report.category.displayName)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(Color.brandDarkBlue)
                }
                
                Spacer()
                
                StatusBadge(status: report.status)
            }
            
            // Content preview
            if !report.reason.isEmpty {
                Text(report.reason)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(2)
            }
            
            // Footer with date and content info
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Reported: \(report.createdDate.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Content ID: \(String(report.reportedContentId.prefix(8)))...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(.white.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 3, y: 1)
    }
    
    private var categoryIcon: String {
        switch report.category {
        case .spam:
            return "exclamationmark.bubble"
        case .harassment:
            return "person.badge.minus"
        case .inappropriateContent:
            return "eye.slash"
        case .falseInformation:
            return "exclamationmark.triangle"
        case .copyright:
            return "c.circle"
        case .other:
            return "flag"
        }
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let status: ReportStatus
    
    var body: some View {
        Text(status.displayName)
            .font(.caption.weight(.medium))
            .foregroundColor(textColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .clipShape(Capsule())
    }
    
    private var backgroundColor: Color {
        switch status {
        case .pending:
            return .orange.opacity(0.2)
        case .underReview:
            return .blue.opacity(0.2)
        case .resolved:
            return .green.opacity(0.2)
        case .dismissed:
            return .gray.opacity(0.2)
        }
    }
    
    private var textColor: Color {
        switch status {
        case .pending:
            return .orange
        case .underReview:
            return .blue
        case .resolved:
            return .green
        case .dismissed:
            return .gray
        }
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let filter: ReportStatusFilter
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.6))
            
            Text("No \(filter.displayName.lowercased()) reports")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Reports will appear here when they match your selected filter.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Preview

struct ModeratorView_Previews: PreviewProvider {
    static var previews: some View {
        ModeratorView()
    }
}