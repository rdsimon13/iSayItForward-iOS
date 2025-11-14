import Foundation

extension String {
    // MARK: - Canonical Delivery Type Constants
    static let oneToOne = "One-to-One"
    static let oneToMany = "One-to-Many"
    static let toGroup = "To Group"
    static let scheduled = "Scheduled"
    static let broadcast = "Broadcast"

    // MARK: - User-Friendly Display Title
    var displayTitle: String {
        switch self.lowercased() {
        case "one-to-one", "onetoone", "one_to_one":
            return "One-to-One"
        case "one-to-many", "onetomany", "one_to_many":
            return "One-to-Many"
        case "to group", "togroup", "group":
            return "To Group"
        case "scheduled", "schedule":
            return "Scheduled"
        case "broadcast", "mass":
            return "Broadcast"
        default:
            return self.capitalized
        }
    }
}
