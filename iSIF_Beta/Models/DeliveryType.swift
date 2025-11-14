import Foundation

public enum DeliveryType: String, Codable, CaseIterable, Identifiable {
    case oneToOne
    case oneToMany
    case toGroup  // canonical name

    public var id: String { rawValue }

    /// UI label used in pickers/buttons
    public var displayTitle: String {
        switch self {
        case .oneToOne:  return "One-to-One"
        case .oneToMany: return "One-to-Many"
        case .toGroup:   return "To Group"
        }
    }

    /// Lossy map from old string values -> enum (keeps legacy code alive)
    public init(fromLegacy value: String) {
        let v = value.lowercased()
        if v.contains("many") { self = .oneToMany }
        else if v.contains("group") { self = .toGroup }
        else { self = .oneToOne }
    }
}

// Extension to handle string-based delivery types from Firestore
extension String {
    public var displayTitle: String {
        switch self {
        case "oneToOne": return "One-to-One"
        case "oneToMany": return "One-to-Many"
        case "toGroup": return "To Group"
        default: return self
        }
    }
}
