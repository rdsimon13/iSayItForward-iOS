import Foundation

// MARK: - Privacy settings view model
@MainActor
class PrivacySettingsViewModel: ObservableObject {
    
    // MARK: - Published properties
    @Published var profileVisibility: ProfileVisibility = .friendsOnly
    @Published var allowDirectMessages = true
    @Published var allowSIFFromStrangers = false
    @Published var showOnlineStatus = true
    @Published var shareActivityStatus = true
    @Published var allowDataCollection = true
    @Published var allowAnalytics = true
    @Published var allowLocationSharing = false
    @Published var allowContactSync = false
    @Published var blockedUsers: [String] = []
    
    // UI state
    @Published var showingBlockedUsers = false
    @Published var showingDataExport = false
    @Published var isExportingData = false
    
    // MARK: - Private properties
    private let settingsService = SettingsService.shared
    
    // MARK: - Update settings
    func updateSettings(_ settings: PrivacySettings) {
        profileVisibility = settings.profileVisibility
        allowDirectMessages = settings.allowDirectMessages
        allowSIFFromStrangers = settings.allowSIFFromStrangers
        showOnlineStatus = settings.showOnlineStatus
        shareActivityStatus = settings.shareActivityStatus
        allowDataCollection = settings.allowDataCollection
        allowAnalytics = settings.allowAnalytics
        allowLocationSharing = settings.allowLocationSharing
        allowContactSync = settings.allowContactSync
        blockedUsers = settings.blockedUsers
    }
    
    // MARK: - Create settings object
    func createPrivacySettings() -> PrivacySettings {
        var settings = PrivacySettings()
        settings.profileVisibility = profileVisibility
        settings.allowDirectMessages = allowDirectMessages
        settings.allowSIFFromStrangers = allowSIFFromStrangers
        settings.showOnlineStatus = showOnlineStatus
        settings.shareActivityStatus = shareActivityStatus
        settings.allowDataCollection = allowDataCollection
        settings.allowAnalytics = allowAnalytics
        settings.allowLocationSharing = allowLocationSharing
        settings.allowContactSync = allowContactSync
        settings.blockedUsers = blockedUsers
        return settings
    }
    
    // MARK: - Save changes
    func saveChanges() async {
        let privacySettings = createPrivacySettings()
        
        do {
            try await settingsService.updatePrivacySettings(privacySettings)
        } catch {
            // Handle error - would be passed up to parent view model
        }
    }
    
    // MARK: - Profile visibility actions
    func setProfileVisibility(_ visibility: ProfileVisibility) async {
        profileVisibility = visibility
        await saveChanges()
    }
    
    // MARK: - Blocking management
    func blockUser(_ userUID: String) async {
        guard !blockedUsers.contains(userUID),
              blockedUsers.count < SettingsConstants.maxBlockedUsersCount else { return }
        
        blockedUsers.append(userUID)
        await saveChanges()
    }
    
    func unblockUser(_ userUID: String) async {
        blockedUsers.removeAll { $0 == userUID }
        await saveChanges()
    }
    
    func clearAllBlockedUsers() async {
        blockedUsers.removeAll()
        await saveChanges()
    }
    
    // MARK: - Data management
    func exportUserData() async {
        isExportingData = true
        
        // This would typically export user data
        // For now, just simulate the process
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        isExportingData = false
        showingDataExport = true
    }
    
    func deleteAllUserData() async {
        // This would trigger a complete data deletion process
        // Implementation would involve multiple services
    }
    
    // MARK: - Privacy presets
    func applyMaxPrivacySettings() async {
        profileVisibility = .privateProfile
        allowDirectMessages = false
        allowSIFFromStrangers = false
        showOnlineStatus = false
        shareActivityStatus = false
        allowDataCollection = false
        allowAnalytics = false
        allowLocationSharing = false
        allowContactSync = false
        
        await saveChanges()
    }
    
    func applyBalancedPrivacySettings() async {
        profileVisibility = .friendsOnly
        allowDirectMessages = true
        allowSIFFromStrangers = false
        showOnlineStatus = true
        shareActivityStatus = true
        allowDataCollection = true
        allowAnalytics = true
        allowLocationSharing = false
        allowContactSync = false
        
        await saveChanges()
    }
    
    func applyOpenPrivacySettings() async {
        profileVisibility = .publicProfile
        allowDirectMessages = true
        allowSIFFromStrangers = true
        showOnlineStatus = true
        shareActivityStatus = true
        allowDataCollection = true
        allowAnalytics = true
        allowLocationSharing = true
        allowContactSync = true
        
        await saveChanges()
    }
    
    // MARK: - Computed properties
    var blockedUsersCount: Int {
        blockedUsers.count
    }
    
    var hasBlockedUsers: Bool {
        !blockedUsers.isEmpty
    }
    
    var privacyLevel: String {
        let settings = createPrivacySettings()
        
        var privacyScore = 0
        if settings.profileVisibility == .privateProfile { privacyScore += 3 }
        else if settings.profileVisibility == .friendsOnly { privacyScore += 2 }
        else { privacyScore += 1 }
        
        if !settings.allowDirectMessages { privacyScore += 1 }
        if !settings.allowSIFFromStrangers { privacyScore += 1 }
        if !settings.showOnlineStatus { privacyScore += 1 }
        if !settings.shareActivityStatus { privacyScore += 1 }
        if !settings.allowDataCollection { privacyScore += 1 }
        if !settings.allowAnalytics { privacyScore += 1 }
        if !settings.allowLocationSharing { privacyScore += 1 }
        if !settings.allowContactSync { privacyScore += 1 }
        
        switch privacyScore {
        case 0...3: return "Open"
        case 4...7: return "Balanced"
        case 8...11: return "High Privacy"
        default: return "Maximum Privacy"
        }
    }
    
    var dataCollectionSummary: String {
        var collected: [String] = []
        if allowDataCollection { collected.append("Usage data") }
        if allowAnalytics { collected.append("Analytics") }
        if allowLocationSharing { collected.append("Location") }
        if allowContactSync { collected.append("Contacts") }
        
        return collected.isEmpty ? "No data collection" : collected.joined(separator: ", ")
    }
}