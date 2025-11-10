import Foundation

struct AppUser: Identifiable, Codable {
    var id: String { uid }
    let uid: String
    let firstName: String
    let lastName: String
    let email: String
    let phoneNumber: String? // ✅ optional for phone auth users

    var fullName: String {
        "\(firstName) \(lastName)"
    }
}
