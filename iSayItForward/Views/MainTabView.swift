import SwiftUI

// Define the tabs for your app
enum AppTab: String, CaseIterable {
    case home = "Home"
    case create = "Create"
    case gallery = "Gallery"
    case profile = "Profile"

    var systemImage: String {
        switch self {
        case .home: return "house.fill"
        case .create: return "plus.circle.fill"
        case .gallery: return "photo.fill.on.rectangle.fill"
        case .profile: return "person.crop.circle.fill"
        }
    }
}

// This struct is your main content view presented after login
struct MainTabView: View {
    @State private var selectedTab: AppTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            // Home View
            GettingStartedView() // Now acting as your initial 'Home' tab content
                .tabItem {
                    Label(AppTab.home.rawValue, systemImage: AppTab.home.systemImage)
                }
                .tag(AppTab.home)

            // Create SIF View (Placeholder)
            CreateSIFView() // Assuming you have this view
                .tabItem {
                    Label(AppTab.create.rawValue, systemImage: AppTab.create.systemImage)
                }
                .tag(AppTab.create)

            // Gallery View (Placeholder)
            TemplateGalleryView() // Assuming you have this view
                .tabItem {
                    Label(AppTab.gallery.rawValue, systemImage: AppTab.gallery.systemImage)
                }
                .tag(AppTab.gallery)

            // Profile/Settings View (Placeholder)
            SettingsView() // Assuming you have this view
                .tabItem {
                    Label(AppTab.profile.rawValue, systemImage: AppTab.profile.systemImage)
                }
                .tag(AppTab.profile)
        }
        .accentColor(Color(hex: "132E37")) // Set the active tab item color
    }
}

#Preview {
    MainTabView()
}
