import Foundation

// MARK: - Privacy settings model
struct PrivacySettings: Codable {
    var profileVisibility: ProfileVisibility
    var allowDirectMessages: Bool
    var allowSIFFromStrangers: Bool
    var showOnlineStatus: Bool
    var shareActivityStatus: Bool
    var allowDataCollection: Bool
    var allowAnalytics: Bool
    var blockedUsers: [String] // UIDs of blocked users
    var allowLocationSharing: Bool
    var allowContactSync: Bool
    
    init() {
        self.profileVisibility = .friendsOnly
        self.allowDirectMessages = true
        self.allowSIFFromStrangers = false
        self.showOnlineStatus = true
        self.shareActivityStatus = true
        self.allowDataCollection = true
        self.allowAnalytics = true
        self.blockedUsers = []
        self.allowLocationSharing = false
        self.allowContactSync = false
    }
}

// MARK: - Profile visibility options
enum ProfileVisibility: String, Codable, CaseIterable {
    case publicProfile = "public"
    case friendsOnly = "friends"
    case privateProfile = "private"
    
    var displayName: String {
        switch self {
        case .publicProfile: return "Public"
        case .friendsOnly: return "Friends Only"
        case .privateProfile: return "Private"
        }
    }
}