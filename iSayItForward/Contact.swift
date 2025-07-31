import Foundation
import FirebaseFirestore

// Contact data model for the Address Book feature
struct Contact: Identifiable, Codable, Hashable, Equatable {
    @DocumentID var id: String?
    
    let ownerUid: String
    var firstName: String
    var lastName: String
    var email: String?
    var phoneNumber: String?
    var category: ContactCategory
    var isFavorite: Bool
    var notes: String?
    let createdDate: Date
    var updatedDate: Date
    
    // Computed property for full name
    var fullName: String {
        return "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }
    
    // Computed property for display name (handles cases where only first or last name exists)
    var displayName: String {
        if firstName.isEmpty && lastName.isEmpty {
            return email ?? phoneNumber ?? "Unknown Contact"
        }
        return fullName
    }
    
    // Hashable & Equatable conformance for SwiftUI lists
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Contact, rhs: Contact) -> Bool {
        lhs.id == rhs.id
    }
    
    // Initialize with current timestamp
    init(ownerUid: String, firstName: String, lastName: String, email: String? = nil, phoneNumber: String? = nil, category: ContactCategory = .personal, isFavorite: Bool = false, notes: String? = nil) {
        self.ownerUid = ownerUid
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.phoneNumber = phoneNumber
        self.category = category
        self.isFavorite = isFavorite
        self.notes = notes
        self.createdDate = Date()
        self.updatedDate = Date()
    }
}

// Contact categories for organization
enum ContactCategory: String, CaseIterable, Codable {
    case personal = "Personal"
    case work = "Work"
    case family = "Family"
    case friends = "Friends"
    case business = "Business"
    case other = "Other"
    
    var iconName: String {
        switch self {
        case .personal:
            return "person.fill"
        case .work:
            return "briefcase.fill"
        case .family:
            return "house.fill"
        case .friends:
            return "person.2.fill"
        case .business:
            return "building.2.fill"
        case .other:
            return "folder.fill"
        }
    }
    
    var color: String {
        switch self {
        case .personal:
            return "#2e385c" // brandDarkBlue
        case .work:
            return "#ffac04" // brandYellow
        case .family:
            return "#ff6b6b" // Red
        case .friends:
            return "#4ecdc4" // Teal
        case .business:
            return "#45b7d1" // Blue
        case .other:
            return "#96ceb4" // Green
        }
    }
}