import SwiftUI

enum SidebarItem: String, CaseIterable, Hashable, Identifiable {
    case home = "Home"
    case createSIF = "Create SIF"
    case manageSIFs = "Manage SIFs"
    case templates = "Templates"
    case profile = "Profile"

    var id: String { self.rawValue }

    var label: some View {
        Text(self.rawValue)
    }
}
