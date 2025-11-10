import SwiftUI

// This struct is your main content view presented after login
struct MainTabView: View {
    @State private var selectedTab: AppTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            // Home View
            GettingStartedView() // Now acting as your initial 'Home' tab content
                .tabItem {
                    Label(AppTab.home.id.capitalized, systemImage: AppTab.home.systemImage)
                }
                .tag(AppTab.home)

            // ✍️ Compose SIF View (replaces .create)
            CreateSIFView() // Assuming you have this view
                .tabItem {
                    Label(AppTab.compose.id.capitalized, systemImage: AppTab.compose.systemImage)
                }
                .tag(AppTab.compose)

            // 🖼️ Gallery View
            TemplateGalleryView(selectedTemplate: .constant(nil))// Assuming you have this view
                .tabItem {
                    Label(AppTab.gallery.id.capitalized, systemImage: AppTab.gallery.systemImage)
                }
                .tag(AppTab.gallery)

            // ⚙️ Profile / Settings View
            SettingsView() // Assuming you have this view
                .tabItem {
                    Label(AppTab.profile.id.capitalized, systemImage: AppTab.profile.systemImage)
                }
                .tag(AppTab.profile)
        }
        .accentColor(Color(hex: "132E37")) // Active tab color
    }
}

#Preview {
    MainTabView()
}
