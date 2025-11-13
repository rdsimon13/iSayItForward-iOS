import Foundation

public enum DeliveryType: String, Codable, CaseIterable, Identifiable {
    case oneToOne
    case oneToMany
    case group

    public var id: String { rawValue }
    public var isMulti: Bool { self == .oneToMany || self == .group }

    public var displayTitle: String {
        switch self {
        case .oneToOne:  return "One to One"
        case .oneToMany: return "One to Many"
        case .group:     return "Group"
        }
    }
}
