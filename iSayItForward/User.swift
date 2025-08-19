import Foundation

// This struct defines the data we will store for each user
// in our Firestore database.
struct User {
    let uid: String
    let name: String
    let email: String
}
