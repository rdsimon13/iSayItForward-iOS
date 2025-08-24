import Foundation
import CoreData

// MARK: - Contact Model
struct Contact: Identifiable, Codable, Hashable {
    let id: UUID
    var firstName: String
    var lastName: String
    var email: String?
    var phoneNumber: String?
    var notes: String?
    var isBlocked: Bool
    var isFavorite: Bool
    var createdDate: Date
    var lastContactedDate: Date?
    var privacyLevel: ContactPrivacyLevel
    var tags: [String]
    var avatarImageData: Data?
    var firebaseId: String?
    
    var fullName: String {
        return "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }
    
    var displayName: String {
        let name = fullName
        return name.isEmpty ? (email ?? phoneNumber ?? "Unknown Contact") : name
    }
    
    var initials: String {
        let firstInitial = firstName.first?.uppercased() ?? ""
        let lastInitial = lastName.first?.uppercased() ?? ""
        return firstInitial + lastInitial
    }
    
    init(id: UUID = UUID(), firstName: String, lastName: String = "", email: String? = nil, phoneNumber: String? = nil) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.phoneNumber = phoneNumber
        self.notes = nil
        self.isBlocked = false
        self.isFavorite = false
        self.createdDate = Date()
        self.lastContactedDate = nil
        self.privacyLevel = .normal
        self.tags = []
        self.avatarImageData = nil
        self.firebaseId = nil
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Contact, rhs: Contact) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Contact Privacy Level
enum ContactPrivacyLevel: Int16, CaseIterable, Codable {
    case normal = 0
    case restricted = 1
    case private_ = 2
    
    var displayName: String {
        switch self {
        case .normal: return "Normal"
        case .restricted: return "Restricted"
        case .private_: return "Private"
        }
    }
    
    var description: String {
        switch self {
        case .normal: return "Standard contact visibility"
        case .restricted: return "Limited visibility and access"
        case .private_: return "Maximum privacy protection"
        }
    }
}

// MARK: - Contact Group Model
struct ContactGroup: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var colorHex: String
    var createdDate: Date
    var isSystemGroup: Bool
    
    init(id: UUID = UUID(), name: String, colorHex: String = "#007AFF", isSystemGroup: Bool = false) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.createdDate = Date()
        self.isSystemGroup = isSystemGroup
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ContactGroup, rhs: ContactGroup) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Contact Activity Model
struct ContactActivity: Identifiable, Codable, Hashable {
    let id: UUID
    var activityType: ContactActivityType
    var activityDate: Date
    var sifId: String?
    var notes: String?
    
    init(id: UUID = UUID(), activityType: ContactActivityType, sifId: String? = nil, notes: String? = nil) {
        self.id = id
        self.activityType = activityType
        self.activityDate = Date()
        self.sifId = sifId
        self.notes = notes
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ContactActivity, rhs: ContactActivity) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Contact Activity Type
enum ContactActivityType: String, CaseIterable, Codable {
    case sifSent = "sif_sent"
    case sifReceived = "sif_received"
    case contactAdded = "contact_added"
    case contactEdited = "contact_edited"
    case contactBlocked = "contact_blocked"
    case contactUnblocked = "contact_unblocked"
    case contactFavorited = "contact_favorited"
    case contactUnfavorited = "contact_unfavorited"
    
    var displayName: String {
        switch self {
        case .sifSent: return "SIF Sent"
        case .sifReceived: return "SIF Received"
        case .contactAdded: return "Contact Added"
        case .contactEdited: return "Contact Edited"
        case .contactBlocked: return "Contact Blocked"
        case .contactUnblocked: return "Contact Unblocked"
        case .contactFavorited: return "Contact Favorited"
        case .contactUnfavorited: return "Contact Unfavorited"
        }
    }
    
    var iconName: String {
        switch self {
        case .sifSent: return "arrow.up.circle"
        case .sifReceived: return "arrow.down.circle"
        case .contactAdded: return "person.badge.plus"
        case .contactEdited: return "person.crop.circle.badge"
        case .contactBlocked: return "person.crop.circle.badge.minus"
        case .contactUnblocked: return "person.crop.circle.badge.plus"
        case .contactFavorited: return "heart.fill"
        case .contactUnfavorited: return "heart"
        }
    }
}

// MARK: - System Contact Groups
extension ContactGroup {
    static let favoriteGroup = ContactGroup(
        name: "Favorites",
        colorHex: "#FF3B30",
        isSystemGroup: true
    )
    
    static let recentGroup = ContactGroup(
        name: "Recent",
        colorHex: "#34C759",
        isSystemGroup: true
    )
    
    static let blockedGroup = ContactGroup(
        name: "Blocked",
        colorHex: "#8E8E93",
        isSystemGroup: true
    )
    
    static let allSystemGroups: [ContactGroup] = [
        favoriteGroup,
        recentGroup,
        blockedGroup
    ]
}