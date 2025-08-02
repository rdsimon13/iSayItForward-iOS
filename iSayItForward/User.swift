import Foundation

// This struct defines the data we will store for each user
// in our Firestore database.
struct User {
    let uid: String
    let name: String
    let email: String
    let isModerator: Bool
    let blockedUsers: [String] // Array of blocked user UIDs
    
    // Initialize with default values for new properties
    init(uid: String, name: String, email: String, isModerator: Bool = false, blockedUsers: [String] = []) {
        self.uid = uid
        self.name = name
        self.email = email
        self.isModerator = isModerator
        self.blockedUsers = blockedUsers
    }
}
