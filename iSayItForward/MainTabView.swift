import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            // ✉️ Create a SIF
            CreateSIFView()
                .tabItem {
                    Label("Compose", systemImage: "square.and.pencil")
                }
                .tag(1)

            // 👤 Profile
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(2)

            // 📅 Schedule
            ScheduleSIFView() // ✅ no arguments now
                .tabItem {
                    Label("Schedule", systemImage: "calendar")
                }
                .tag(3)

            // 🚀 Getting Started (or Settings)
            GettingStartedView()
                .tabItem {
                    Label("Getting Started", systemImage: "figure.walk")
                }
                .tag(4)
        }
    }
}

#Preview {
    MainTabView()
}
