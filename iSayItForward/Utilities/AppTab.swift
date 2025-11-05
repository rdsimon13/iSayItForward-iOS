import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case home
    case compose
    case profile
    case schedule
    case gallery
    case settings

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .home: return "house.fill"
        case .compose: return "square.and.pencil"
        case .profile: return "person.fill"
        case .schedule: return "calendar"
        case .gallery: return "photo.on.rectangle"
        case .settings: return "gearshape.fill"
        }
    }

    var title: String {
        switch self {
        case .home: return "Home"
        case .compose: return "Compose"
        case .profile: return "Profile"
        case .schedule: return "Schedule"
        case .gallery: return "Gallery"
        case .settings: return "Settings"
        }
    }
}
