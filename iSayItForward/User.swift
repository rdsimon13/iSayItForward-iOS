import Foundation

struct User: Identifiable, Codable {
    var id = UUID().uuidString
    var firstName: String
    var lastName: String
    var email: String
    var uid: String

    var fullName: String {
        "\(firstName) \(lastName)"
    }
}
