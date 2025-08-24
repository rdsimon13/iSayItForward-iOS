import Foundation

// MARK: - Profile settings model
struct ProfileSettings: Codable {
    var displayName: String
    var bio: String
    var location: String
    var website: String
    var phoneNumber: String
    var skills: [String]
    var expertise: [String]
    var profileImageURL: String?
    var isProfileComplete: Bool
    
    init() {
        self.displayName = ""
        self.bio = ""
        self.location = ""
        self.website = ""
        self.phoneNumber = ""
        self.skills = []
        self.expertise = []
        self.profileImageURL = nil
        self.isProfileComplete = false
    }
}