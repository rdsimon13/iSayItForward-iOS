import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Int = 0
    @State private var scheduledDate: Date = Date() // ✅ Fix: Create state var for binding

    var body: some View {
        TabView(selection: $selectedTab) {
            
            // 🏠 Home
            HomeView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            // 🖊️ Create a SIF
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
            ScheduleSIFView(scheduledDate: $scheduledDate) // ✅ Pass the state binding here
                .tabItem {
                    Label("Schedule", systemImage: "calendar")
                }
                .tag(3)

            // 🚀 Getting Started (replaces Settings for now)
            GettingStartedView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Getting Started", systemImage: "figure.walk")
                }
                .tag(4)
        }
    }
}
