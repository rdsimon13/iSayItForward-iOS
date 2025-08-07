import Foundation
import FirebaseAuth
import FirebaseFirestore

// MARK: - Settings Data Models
struct SIFPreferences: Codable {
    var defaultSubject: String
    var defaultMessage: String
    var autoSave: Bool
    var useTemplates: Bool
    
    // Notification preferences
    var notificationsEnabled: Bool
    var scheduledReminders: Bool
    var deliveryConfirmations: Bool
    
    // Privacy settings
    var shareStatistics: Bool
    var allowAnonymousFeedback: Bool
    
    // Scheduling preferences
    var defaultScheduleTime: String // HH:mm format
    var timeZone: String
    var weekendScheduling: Bool
    
    static let defaultPreferences = SIFPreferences(
        defaultSubject: "",
        defaultMessage: "",
        autoSave: true,
        useTemplates: true,
        notificationsEnabled: true,
        scheduledReminders: true,
        deliveryConfirmations: true,
        shareStatistics: false,
        allowAnonymousFeedback: true,
        defaultScheduleTime: "09:00",
        timeZone: TimeZone.current.identifier,
        weekendScheduling: false
    )
}

struct SIFStatistics: Codable {
    var totalSIFsSent: Int
    var totalSIFsScheduled: Int
    var totalSIFsReceived: Int
    var averageResponseTime: Double // in hours
    var mostUsedTemplate: String?
    var longestStreak: Int // consecutive days with SIF activity
    var currentStreak: Int
    var lastActivityDate: Date?
    var impactScore: Double // calculated metric
    
    static let emptyStatistics = SIFStatistics(
        totalSIFsSent: 0,
        totalSIFsScheduled: 0,
        totalSIFsReceived: 0,
        averageResponseTime: 0.0,
        mostUsedTemplate: nil,
        longestStreak: 0,
        currentStreak: 0,
        lastActivityDate: nil,
        impactScore: 0.0
    )
}

// MARK: - Settings Manager
class SIFSettingsManager: ObservableObject {
    @Published var preferences: SIFPreferences
    @Published var statistics: SIFStatistics
    @Published var isLoading: Bool = false
    
    private let db = Firestore.firestore()
    private var userUID: String? {
        return Auth.auth().currentUser?.uid
    }
    
    init() {
        self.preferences = SIFPreferences.defaultPreferences
        self.statistics = SIFStatistics.emptyStatistics
        loadSettings()
    }
    
    // MARK: - Settings Loading
    func loadSettings() {
        guard let uid = userUID else { return }
        
        isLoading = true
        
        // Load preferences
        db.collection("userSettings").document(uid).getDocument { [weak self] snapshot, error in
            DispatchQueue.main.async {
                if let document = snapshot, document.exists,
                   let data = document.data(),
                   let preferencesData = try? JSONSerialization.data(withJSONObject: data),
                   let preferences = try? JSONDecoder().decode(SIFPreferences.self, from: preferencesData) {
                    self?.preferences = preferences
                } else {
                    self?.preferences = SIFPreferences.defaultPreferences
                    self?.savePreferences() // Save defaults on first load
                }
                self?.isLoading = false
            }
        }
        
        // Load statistics
        loadStatistics()
    }
    
    private func loadStatistics() {
        guard let uid = userUID else { return }
        
        db.collection("userStatistics").document(uid).getDocument { [weak self] snapshot, error in
            DispatchQueue.main.async {
                if let document = snapshot, document.exists,
                   let data = document.data(),
                   let statisticsData = try? JSONSerialization.data(withJSONObject: data),
                   let statistics = try? JSONDecoder().decode(SIFStatistics.self, from: statisticsData) {
                    self?.statistics = statistics
                } else {
                    self?.statistics = SIFStatistics.emptyStatistics
                }
            }
        }
    }
    
    // MARK: - Settings Saving
    func savePreferences() {
        guard let uid = userUID else { return }
        
        do {
            let data = try JSONEncoder().encode(preferences)
            let dictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
            
            db.collection("userSettings").document(uid).setData(dictionary) { error in
                if let error = error {
                    print("Error saving preferences: \(error.localizedDescription)")
                }
            }
        } catch {
            print("Error encoding preferences: \(error.localizedDescription)")
        }
    }
    
    func updateStatistics(_ newStatistics: SIFStatistics) {
        guard let uid = userUID else { return }
        
        self.statistics = newStatistics
        
        do {
            let data = try JSONEncoder().encode(newStatistics)
            let dictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
            
            db.collection("userStatistics").document(uid).setData(dictionary) { error in
                if let error = error {
                    print("Error saving statistics: \(error.localizedDescription)")
                }
            }
        } catch {
            print("Error encoding statistics: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Settings Validation
    func validatePreferences() -> [String] {
        var errors: [String] = []
        
        if preferences.defaultScheduleTime.isEmpty {
            errors.append("Default schedule time cannot be empty")
        } else if !isValidTimeFormat(preferences.defaultScheduleTime) {
            errors.append("Default schedule time must be in HH:mm format")
        }
        
        if preferences.timeZone.isEmpty {
            errors.append("Time zone cannot be empty")
        }
        
        return errors
    }
    
    private func isValidTimeFormat(_ time: String) -> Bool {
        let timeFormat = DateFormatter()
        timeFormat.dateFormat = "HH:mm"
        return timeFormat.date(from: time) != nil
    }
    
    // MARK: - Utility Methods
    func resetToDefaults() {
        preferences = SIFPreferences.defaultPreferences
        savePreferences()
    }
    
    func incrementSIFsSent() {
        var newStats = statistics
        newStats.totalSIFsSent += 1
        newStats.lastActivityDate = Date()
        updateCurrentStreak(&newStats)
        calculateImpactScore(&newStats)
        updateStatistics(newStats)
    }
    
    func incrementSIFsScheduled() {
        var newStats = statistics
        newStats.totalSIFsScheduled += 1
        newStats.lastActivityDate = Date()
        updateCurrentStreak(&newStats)
        calculateImpactScore(&newStats)
        updateStatistics(newStats)
    }
    
    private func updateCurrentStreak(_ stats: inout SIFStatistics) {
        guard let lastActivity = stats.lastActivityDate else {
            stats.currentStreak = 1
            return
        }
        
        let calendar = Calendar.current
        let today = Date()
        
        if calendar.isDate(lastActivity, inSameDayAs: today) {
            // Same day, don't change streak
            return
        } else if calendar.isDate(lastActivity, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: today) ?? today) {
            // Yesterday, increment streak
            stats.currentStreak += 1
            if stats.currentStreak > stats.longestStreak {
                stats.longestStreak = stats.currentStreak
            }
        } else {
            // More than a day ago, reset streak
            stats.currentStreak = 1
        }
    }
    
    private func calculateImpactScore(_ stats: inout SIFStatistics) {
        // Simple impact score calculation based on activity
        let totalActivity = Double(stats.totalSIFsSent + stats.totalSIFsScheduled)
        let streakBonus = Double(stats.currentStreak) * 0.1
        stats.impactScore = totalActivity + streakBonus
    }
}