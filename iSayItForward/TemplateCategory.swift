import SwiftUI

// MARK: - Template Category Enum
enum TemplateCategory: String, CaseIterable, Identifiable {
    case encouragement = "Encouragement"
    case holiday = "Holiday"
    case school = "School"
    case patriotic = "Patriotic"
    case spiritual = "Spiritual"
    case celebration = "Celebration"
    case appreciation = "Appreciation"

    var id: String { self.rawValue }

    var icon: String {
        switch self {
        case .encouragement: return "sun.max.fill"
        case .holiday: return "gift.fill"
        case .school: return "graduationcap.fill"
        case .patriotic: return "flag.fill"
        case .spiritual: return "sparkles"
        case .celebration: return "party.popper.fill"
        case .appreciation: return "heart.text.square.fill"
        }
    }

    var color: Color {
        switch self {
        case .encouragement: return Color(red: 0.0, green: 0.7, blue: 1.0)
        case .holiday: return Color(red: 1.0, green: 0.5, blue: 0.3)
        case .school: return Color(red: 0.25, green: 0.6, blue: 1.0)
        case .patriotic: return Color(red: 0.85, green: 0.1, blue: 0.1)
        case .spiritual: return Color(red: 0.55, green: 0.35, blue: 0.85)
        case .celebration: return Color(red: 1.0, green: 0.8, blue: 0.2)
        case .appreciation: return Color(red: 1.0, green: 0.65, blue: 0.3)
        }
    }

    var displayTitle: String {
        switch self {
        case .encouragement: return "Encouragement"
        case .holiday: return "Holiday Greetings"
        case .school: return "School & Academic"
        case .patriotic: return "Patriotic & Tribute"
        case .spiritual: return "Spiritual Reflections"
        case .celebration: return "Celebrations & Events"
        case .appreciation: return "Appreciation & Thanks"
        }
    }
}
