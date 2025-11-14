import Foundation

public enum AppTab: String, CaseIterable {
    case home
    case compose
    case gallery
    case schedule
    case sifConnect
    case profile

    public var title: String {
        switch self {
        case .home: return "Home"
        case .compose: return "Compose"
        case .gallery: return "Gallery"
        case .schedule: return "Schedule"
        case .sifConnect: return "Connect"
        case .profile: return "Profile"
        }
    }

    public var systemImage: String {
        switch self {
        case .home: return "house.fill"
        case .compose: return "plus.circle.fill"
        case .gallery: return "photo.stack.fill"
        case .schedule: return "calendar.circle.fill"
        case .sifConnect: return "person.2.fill"
        case .profile: return "person.crop.circle.fill"
        }
    }
}
