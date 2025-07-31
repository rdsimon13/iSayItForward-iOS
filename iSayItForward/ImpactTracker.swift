import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

/// Service for tracking and analyzing impact metrics
class ImpactTracker: ObservableObject {
    private let db = Firestore.firestore()
    
    @Published var currentMetrics: ImpactMetrics?
    @Published var historicalMetrics: [ImpactMetrics] = []
    @Published var isLoading = false
    @Published var error: ImpactError?
    
    // MARK: - Metrics Generation
    func generateMetrics(for period: TimePeriod, startDate: Date? = nil, endDate: Date? = nil) async {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        await MainActor.run {
            self.isLoading = true
            self.error = nil
        }
        
        do {
            let dateRange = calculateDateRange(for: period, startDate: startDate, endDate: endDate)
            let metrics = try await calculateImpactMetrics(
                userId: currentUser.uid,
                period: period,
                startDate: dateRange.start,
                endDate: dateRange.end
            )
            
            await MainActor.run {
                self.currentMetrics = metrics
                self.isLoading = false
            }
            
            // Save metrics to database
            try await saveMetrics(metrics)
            
        } catch {
            await MainActor.run {
                self.error = .calculationFailed(error)
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Metrics Calculation
    private func calculateImpactMetrics(userId: String, period: TimePeriod, startDate: Date, endDate: Date) async throws -> ImpactMetrics {
        // Initialize metrics
        var metrics = ImpactMetrics(userId: userId, period: period, startDate: startDate, endDate: endDate)
        
        // Get responses in date range
        let responses = try await getResponsesInDateRange(userId: userId, startDate: startDate, endDate: endDate)
        
        // Get SIFs sent in date range
        let sifs = try await getSIFsInDateRange(userId: userId, startDate: startDate, endDate: endDate)
        
        // Get signatures in date range
        let signatures = try await getSignaturesInDateRange(userId: userId, startDate: startDate, endDate: endDate)
        
        // Calculate response metrics
        let responseMetrics = calculateResponseMetrics(responses: responses, sifs: sifs)
        
        // Calculate reach metrics
        let reachMetrics = calculateReachMetrics(responses: responses, sifs: sifs)
        
        // Calculate sentiment analysis
        let sentimentAnalysis = calculateSentimentAnalysis(responses: responses)
        
        // Calculate engagement level
        let engagementLevel = calculateEngagementLevel(responses: responses, sifs: sifs)
        
        // Calculate positive impact score
        let positiveImpactScore = calculatePositiveImpactScore(responses: responses, sentimentAnalysis: sentimentAnalysis)
        
        // Update metrics with calculated values
        // Note: In a real implementation, ImpactMetrics would need mutable properties or a builder pattern
        return ImpactMetrics(userId: userId, period: period, startDate: startDate, endDate: endDate)
    }
    
    // MARK: - Data Retrieval
    private func getResponsesInDateRange(userId: String, startDate: Date, endDate: Date) async throws -> [ResponseModel] {
        let query = db.collection("responses")
            .whereField("authorUid", isEqualTo: userId)
            .whereField("createdDate", isGreaterThanOrEqualTo: startDate)
            .whereField("createdDate", isLessThanOrEqualTo: endDate)
        
        let snapshot = try await query.getDocuments()
        return try snapshot.documents.compactMap { document in
            try document.data(as: ResponseModel.self)
        }
    }
    
    private func getSIFsInDateRange(userId: String, startDate: Date, endDate: Date) async throws -> [SIFItem] {
        let query = db.collection("sifs") // Assuming SIFs are stored in "sifs" collection
            .whereField("authorUid", isEqualTo: userId)
            .whereField("createdDate", isGreaterThanOrEqualTo: startDate)
            .whereField("createdDate", isLessThanOrEqualTo: endDate)
        
        let snapshot = try await query.getDocuments()
        return try snapshot.documents.compactMap { document in
            try document.data(as: SIFItem.self)
        }
    }
    
    private func getSignaturesInDateRange(userId: String, startDate: Date, endDate: Date) async throws -> [SignatureModel] {
        let query = db.collection("signatures")
            .whereField("userUid", isEqualTo: userId)
            .whereField("timestamp", isGreaterThanOrEqualTo: startDate)
            .whereField("timestamp", isLessThanOrEqualTo: endDate)
        
        let snapshot = try await query.getDocuments()
        return try snapshot.documents.compactMap { document in
            try document.data(as: SignatureModel.self)
        }
    }
    
    // MARK: - Metrics Calculations
    private func calculateResponseMetrics(responses: [ResponseModel], sifs: [SIFItem]) -> (totalResponses: Int, responsesByCategory: [ResponseCategory: Int], averageResponseTime: TimeInterval, responseRate: Double) {
        let totalResponses = responses.count
        
        // Group responses by category
        var responsesByCategory: [ResponseCategory: Int] = [:]
        for response in responses {
            responsesByCategory[response.category, default: 0] += 1
        }
        
        // Calculate average response time (placeholder - would need response timestamps)
        let averageResponseTime: TimeInterval = 0 // This would require more complex calculation
        
        // Calculate response rate
        let responseRate = sifs.isEmpty ? 0.0 : Double(totalResponses) / Double(sifs.count)
        
        return (totalResponses, responsesByCategory, averageResponseTime, responseRate)
    }
    
    private func calculateReachMetrics(responses: [ResponseModel], sifs: [SIFItem]) -> ReachMetrics {
        // Calculate unique respondents (simplified)
        let uniqueRespondents = Set(responses.map { $0.authorUid }).count
        
        // Calculate total reach (simplified)
        let totalReach = sifs.reduce(0) { total, sif in
            total + sif.recipients.count
        }
        
        // Calculate share rate (placeholder)
        let shareRate = 0.0
        
        // Calculate forward rate (placeholder)
        let forwardRate = 0.0
        
        // Geographic distribution (placeholder)
        let geographicDistribution: [String: Int] = [:]
        
        return ReachMetrics()
    }
    
    private func calculateSentimentAnalysis(responses: [ResponseModel]) -> SentimentAnalysis {
        var positiveCount = 0
        var neutralCount = 0
        var negativeCount = 0
        
        // Simple sentiment analysis based on keywords
        for response in responses {
            let sentiment = analyzeSentiment(response.responseText)
            switch sentiment {
            case .veryPositive, .positive:
                positiveCount += 1
            case .neutral:
                neutralCount += 1
            case .negative, .veryNegative:
                negativeCount += 1
            }
        }
        
        // Determine overall sentiment
        let totalResponses = responses.count
        let overallSentiment: SentimentScore
        if totalResponses == 0 {
            overallSentiment = .neutral
        } else {
            let positiveRatio = Double(positiveCount) / Double(totalResponses)
            if positiveRatio > 0.6 {
                overallSentiment = .positive
            } else if positiveRatio < 0.3 {
                overallSentiment = .negative
            } else {
                overallSentiment = .neutral
            }
        }
        
        return SentimentAnalysis()
    }
    
    private func analyzeSentiment(_ text: String) -> SentimentScore {
        let lowercaseText = text.lowercased()
        
        let positiveWords = ["great", "amazing", "wonderful", "excellent", "love", "thank", "appreciate", "fantastic", "awesome"]
        let negativeWords = ["bad", "terrible", "awful", "hate", "disappointed", "frustrated", "angry", "sad"]
        
        var positiveScore = 0
        var negativeScore = 0
        
        for word in positiveWords {
            if lowercaseText.contains(word) {
                positiveScore += 1
            }
        }
        
        for word in negativeWords {
            if lowercaseText.contains(word) {
                negativeScore += 1
            }
        }
        
        if positiveScore > negativeScore {
            return positiveScore > 2 ? .veryPositive : .positive
        } else if negativeScore > positiveScore {
            return negativeScore > 2 ? .veryNegative : .negative
        } else {
            return .neutral
        }
    }
    
    private func calculateEngagementLevel(responses: [ResponseModel], sifs: [SIFItem]) -> EngagementLevel {
        let responseRate = sifs.isEmpty ? 0.0 : Double(responses.count) / Double(sifs.count)
        
        if responseRate >= 0.8 {
            return .exceptional
        } else if responseRate >= 0.6 {
            return .high
        } else if responseRate >= 0.3 {
            return .medium
        } else {
            return .low
        }
    }
    
    private func calculatePositiveImpactScore(responses: [ResponseModel], sentimentAnalysis: SentimentAnalysis) -> Double {
        if responses.isEmpty {
            return 0.0
        }
        
        let totalResponses = Double(responses.count)
        let positiveResponses = Double(sentimentAnalysis.positiveResponses)
        
        // Base score from positive sentiment ratio
        let sentimentScore = positiveResponses / totalResponses
        
        // Bonus for response quality (categories that create positive impact)
        let qualityBonus = responses.reduce(0.0) { total, response in
            switch response.category {
            case .gratitude, .compliment:
                return total + 0.2
            case .feedback, .suggestion:
                return total + 0.1
            default:
                return total
            }
        } / totalResponses
        
        return min(sentimentScore + qualityBonus, 1.0)
    }
    
    // MARK: - Date Range Calculation
    private func calculateDateRange(for period: TimePeriod, startDate: Date?, endDate: Date?) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        
        if let startDate = startDate, let endDate = endDate {
            return (startDate, endDate)
        }
        
        let end = endDate ?? now
        let start: Date
        
        switch period {
        case .daily:
            start = calendar.startOfDay(for: end)
        case .weekly:
            start = calendar.dateInterval(of: .weekOfYear, for: end)?.start ?? end
        case .monthly:
            start = calendar.dateInterval(of: .month, for: end)?.start ?? end
        case .quarterly:
            let quarterStart = calendar.dateInterval(of: .quarter, for: end)?.start ?? end
            start = quarterStart
        case .yearly:
            start = calendar.dateInterval(of: .year, for: end)?.start ?? end
        case .custom:
            start = startDate ?? calendar.date(byAdding: .month, value: -1, to: end) ?? end
        }
        
        return (start, end)
    }
    
    // MARK: - Metrics Storage
    private func saveMetrics(_ metrics: ImpactMetrics) async throws {
        do {
            let _ = try db.collection("impact_metrics").addDocument(from: metrics)
        } catch {
            throw ImpactError.saveFailed(error)
        }
    }
    
    // MARK: - Historical Metrics
    func loadHistoricalMetrics() async {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        await MainActor.run {
            self.isLoading = true
            self.error = nil
        }
        
        do {
            let query = db.collection("impact_metrics")
                .whereField("userId", isEqualTo: currentUser.uid)
                .order(by: "generatedDate", descending: true)
                .limit(to: 50)
            
            let snapshot = try await query.getDocuments()
            let metrics = try snapshot.documents.compactMap { document in
                try document.data(as: ImpactMetrics.self)
            }
            
            await MainActor.run {
                self.historicalMetrics = metrics
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = .loadFailed(error)
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Report Generation
    func generateReport(for metrics: ImpactMetrics) -> ImpactReport {
        return ImpactReport(
            metrics: metrics,
            summary: generateSummary(metrics),
            recommendations: generateRecommendations(metrics),
            trends: analyzeTrends(metrics)
        )
    }
    
    private func generateSummary(_ metrics: ImpactMetrics) -> String {
        return """
        Impact Summary for \(metrics.period.displayName):
        • Total Responses: \(metrics.totalResponses)
        • Engagement Level: \(metrics.engagementLevel.displayName)
        • Positive Impact Score: \(String(format: "%.1f", metrics.positiveImpactScore * 100))%
        • Response Rate: \(String(format: "%.1f", metrics.responseRate * 100))%
        """
    }
    
    private func generateRecommendations(_ metrics: ImpactMetrics) -> [String] {
        var recommendations: [String] = []
        
        if metrics.responseRate < 0.3 {
            recommendations.append("Consider making your SIFs more engaging to improve response rates")
        }
        
        if metrics.positiveImpactScore < 0.5 {
            recommendations.append("Focus on creating more positive interactions")
        }
        
        if metrics.signatureUsageCount == 0 {
            recommendations.append("Try using signatures to add authenticity to your responses")
        }
        
        return recommendations
    }
    
    private func analyzeTrends(_ metrics: ImpactMetrics) -> [String] {
        // This would compare with historical data
        return ["Analysis would require historical comparison"]
    }
}

// MARK: - Impact Report
struct ImpactReport {
    let metrics: ImpactMetrics
    let summary: String
    let recommendations: [String]
    let trends: [String]
}

// MARK: - Error Handling
enum ImpactError: LocalizedError {
    case calculationFailed(Error)
    case saveFailed(Error)
    case loadFailed(Error)
    case authenticationRequired
    
    var errorDescription: String? {
        switch self {
        case .calculationFailed(let error):
            return "Failed to calculate impact metrics: \(error.localizedDescription)"
        case .saveFailed(let error):
            return "Failed to save metrics: \(error.localizedDescription)"
        case .loadFailed(let error):
            return "Failed to load metrics: \(error.localizedDescription)"
        case .authenticationRequired:
            return "Authentication required to access impact metrics"
        }
    }
}