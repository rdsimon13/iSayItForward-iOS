import Foundation

public enum DeliveryType: String, Codable, CaseIterable, Identifiable {
    case oneToOne
    case oneToMany
    case toGroup

    public var id: String { rawValue }
    public var isMulti: Bool { self != .oneToOne }

    public var displayTitle: String {
        switch self {
        case .oneToOne:  return "One to One"
        case .oneToMany: return "One to Many"
        case .toGroup:   return "Group"
        }
    }
}
