import SwiftUI

enum SidebarItem: String, CaseIterable, Identifiable, Hashable {
    case home
    case createSIF
    case manageSIFs
    case gallery
    case profile

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "Home"
        case .createSIF: return "Create SIF"
        case .manageSIFs: return "My SIFs"
        case .gallery: return "Gallery"
        case .profile: return "Profile"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house"
        case .createSIF: return "square.and.pencil"
        case .manageSIFs: return "tray.full"
        case .gallery: return "photo.on.rectangle"
        case .profile: return "person.crop.circle"
        }
    }

    @ViewBuilder
    var label: some View {
        Label(title, systemImage: icon)
            .font(.system(size: 16, weight: .medium, design: .rounded))
            .foregroundColor(.primary)
    }
}
