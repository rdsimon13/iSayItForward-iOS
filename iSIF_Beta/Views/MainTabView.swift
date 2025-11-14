import SwiftUI

// This struct is your main content view presented after login
struct MainTabView: View {
    @State private var selectedTab: AppTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            // Home View
            GettingStartedView() // Now acting as your initial 'Home' tab content
                .tabItem {
                    Label(AppTab.home.title, systemImage: AppTab.home.systemImage)
                }
                .tag(AppTab.home)

            // ✍️ Compose SIF View (replaces .create)
            CreateSIFView() // Assuming you have this view
                .tabItem {
                    Label(AppTab.compose.title, systemImage: AppTab.compose.systemImage)
                }
                .tag(AppTab.compose)

            // 🖼️ Gallery View
            TemplateGalleryView(selectedTemplate: .constant(nil))// Assuming you have this view
                .tabItem {
                    Label(AppTab.gallery.title, systemImage: AppTab.gallery.systemImage)
                }
                .tag(AppTab.gallery)

            // 📅 Schedule View
            ScheduleSIFView()
                .tabItem {
                    Label(AppTab.schedule.title, systemImage: AppTab.schedule.systemImage)
                }
                .tag(AppTab.schedule)

            // 👥 Connect View
            AllUsersView()
                .tabItem {
                    Label(AppTab.sifConnect.title, systemImage: AppTab.sifConnect.systemImage)
                }
                .tag(AppTab.sifConnect)

            // 👤 Profile View
            ProfileView()
                .tabItem {
                    Label(AppTab.profile.title, systemImage: AppTab.profile.systemImage)
                }
                .tag(AppTab.profile)
        }
        .accentColor(Color(hex: "132E37")) // Active tab color
    }
}

#Preview {
    MainTabView()
}
