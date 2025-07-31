import SwiftUI

/// View for displaying impact statistics and analytics
struct ImpactMetricsView: View {
    @StateObject private var impactTracker = ImpactTracker()
    
    @State private var selectedPeriod: TimePeriod = .monthly
    @State private var showingReportDetails = false
    @State private var showingPeriodPicker = false
    @State private var customStartDate = Date()
    @State private var customEndDate = Date()
    @State private var showingCustomDatePicker = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Period Selection
                    periodSelectionSection
                    
                    // Main Metrics Cards
                    if let metrics = impactTracker.currentMetrics {
                        mainMetricsSection(metrics)
                        
                        // Detailed Analytics
                        detailedAnalyticsSection(metrics)
                        
                        // Response Categories Chart
                        responseCategoriesChart(metrics)
                        
                        // Engagement Trends
                        engagementTrendsSection(metrics)
                        
                        // Impact Report
                        impactReportSection(metrics)
                    } else if impactTracker.isLoading {
                        loadingView
                    } else {
                        emptyStateView
                    }
                }
                .padding()
            }
            .navigationTitle("Impact Analytics")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await generateMetrics()
            }
            .task {
                await generateMetrics()
            }
        }
        .sheet(isPresented: $showingCustomDatePicker) {
            customDatePickerSheet
        }
        .alert("Error", isPresented: .constant(impactTracker.error != nil)) {
            Button("OK") {
                impactTracker.error = nil
            }
        } message: {
            if let error = impactTracker.error {
                Text(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Period Selection
    
    private var periodSelectionSection: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Time Period")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    showingPeriodPicker = true
                }) {
                    HStack {
                        Text(selectedPeriod.displayName)
                        Image(systemName: "chevron.down")
                    }
                    .foregroundColor(.blue)
                }
            }
            
            if selectedPeriod == .custom {
                HStack {
                    Text("Custom Range:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button(action: {
                        showingCustomDatePicker = true
                    }) {
                        Text("\(formatDate(customStartDate)) - \(formatDate(customEndDate))")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .actionSheet(isPresented: $showingPeriodPicker) {
            ActionSheet(
                title: Text("Select Time Period"),
                buttons: TimePeriod.allCases.map { period in
                    .default(Text(period.displayName)) {
                        selectedPeriod = period
                        Task {
                            await generateMetrics()
                        }
                    }
                } + [.cancel()]
            )
        }
    }
    
    // MARK: - Main Metrics
    
    private func mainMetricsSection(_ metrics: ImpactMetrics) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 15) {
            MetricCard(
                title: "Total Responses",
                value: "\(metrics.totalResponses)",
                icon: "bubble.left.and.bubble.right.fill",
                color: .blue
            )
            
            MetricCard(
                title: "Response Rate",
                value: "\(Int(metrics.responseRate * 100))%",
                icon: "chart.line.uptrend.xyaxis",
                color: .green
            )
            
            MetricCard(
                title: "Impact Score",
                value: "\(Int(metrics.positiveImpactScore * 100))",
                icon: "heart.fill",
                color: .red
            )
            
            MetricCard(
                title: "Engagement",
                value: metrics.engagementLevel.displayName,
                icon: "person.3.fill",
                color: Color(metrics.engagementLevel.color)
            )
        }
    }
    
    // MARK: - Detailed Analytics
    
    private func detailedAnalyticsSection(_ metrics: ImpactMetrics) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Detailed Analytics")
                .font(.headline)
            
            VStack(spacing: 12) {
                AnalyticsRow(
                    title: "Unique Respondents",
                    value: "\(metrics.reachMetrics.uniqueRespondents)",
                    icon: "person.circle.fill"
                )
                
                AnalyticsRow(
                    title: "Total Reach",
                    value: "\(metrics.reachMetrics.totalReach)",
                    icon: "antenna.radiowaves.left.and.right"
                )
                
                AnalyticsRow(
                    title: "Signatures Used",
                    value: "\(metrics.signatureUsageCount)",
                    icon: "signature"
                )
                
                AnalyticsRow(
                    title: "Documents Signed",
                    value: "\(metrics.documentsSignedCount)",
                    icon: "doc.text.fill"
                )
                
                AnalyticsRow(
                    title: "Overall Sentiment",
                    value: metrics.sentimentAnalysis.overallSentiment.displayName,
                    icon: "face.smiling.fill"
                )
                
                if metrics.averageResponseTime > 0 {
                    AnalyticsRow(
                        title: "Avg Response Time",
                        value: formatResponseTime(metrics.averageResponseTime),
                        icon: "clock.fill"
                    )
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Response Categories Chart
    
    private func responseCategoriesChart(_ metrics: ImpactMetrics) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Response Categories")
                .font(.headline)
            
            if !metrics.responsesByCategory.isEmpty {
                VStack {
                    // Chart would go here - simplified for now
                    ForEach(Array(metrics.responsesByCategory.keys), id: \.self) { category in
                        HStack {
                            HStack {
                                Image(systemName: category.iconName)
                                    .foregroundColor(.blue)
                                Text(category.displayName)
                                    .font(.subheadline)
                            }
                            
                            Spacer()
                            
                            Text("\(metrics.responsesByCategory[category] ?? 0)")
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        .padding(.vertical, 5)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else {
                Text("No response data available")
                    .foregroundColor(.secondary)
                    .italic()
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Engagement Trends
    
    private func engagementTrendsSection(_ metrics: ImpactMetrics) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Engagement Analysis")
                .font(.headline)
            
            VStack(spacing: 12) {
                EngagementBar(
                    title: "Positive Responses",
                    count: metrics.sentimentAnalysis.positiveResponses,
                    total: metrics.totalResponses,
                    color: .green
                )
                
                EngagementBar(
                    title: "Neutral Responses",
                    count: metrics.sentimentAnalysis.neutralResponses,
                    total: metrics.totalResponses,
                    color: .orange
                )
                
                EngagementBar(
                    title: "Negative Responses",
                    count: metrics.sentimentAnalysis.negativeResponses,
                    total: metrics.totalResponses,
                    color: .red
                )
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Impact Report
    
    private func impactReportSection(_ metrics: ImpactMetrics) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Impact Report")
                    .font(.headline)
                
                Spacer()
                
                Button("View Details") {
                    showingReportDetails = true
                }
                .foregroundColor(.blue)
            }
            
            let report = impactTracker.generateReport(for: metrics)
            
            VStack(alignment: .leading, spacing: 10) {
                Text(report.summary)
                    .font(.body)
                    .foregroundColor(.secondary)
                
                if !report.recommendations.isEmpty {
                    Text("Recommendations:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.top, 5)
                    
                    ForEach(report.recommendations, id: \.self) { recommendation in
                        HStack(alignment: .top) {
                            Text("•")
                                .foregroundColor(.blue)
                            Text(recommendation)
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
    }
    
    // MARK: - Supporting Views
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Analyzing your impact...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No Analytics Available")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Start creating responses to see your impact metrics here.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Generate Metrics") {
                Task {
                    await generateMetrics()
                }
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }
    
    private var customDatePickerSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                DatePicker("Start Date", selection: $customStartDate, displayedComponents: .date)
                DatePicker("End Date", selection: $customEndDate, displayedComponents: .date)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Custom Date Range")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingCustomDatePicker = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        showingCustomDatePicker = false
                        Task {
                            await generateMetrics()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func generateMetrics() async {
        if selectedPeriod == .custom {
            await impactTracker.generateMetrics(
                for: selectedPeriod,
                startDate: customStartDate,
                endDate: customEndDate
            )
        } else {
            await impactTracker.generateMetrics(for: selectedPeriod)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatResponseTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Supporting Views

struct MetricCard: View {
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
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct AnalyticsRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }
}

struct EngagementBar: View {
    let title: String
    let count: Int
    let total: Int
    let color: Color
    
    private var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(count) / Double(total)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.subheadline)
                
                Spacer()
                
                Text("\(count) (\(Int(percentage * 100))%)")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * percentage, height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Preview
struct ImpactMetricsView_Previews: PreviewProvider {
    static var previews: some View {
        ImpactMetricsView()
    }
}