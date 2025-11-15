import SwiftUI

// This struct is your main content view presented after login
struct MainTabView: View {
    @StateObject private var router = TabRouter()
    @StateObject private var authState = AuthState()
    @State private var selectedTab: AppTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            // Home View
            GettingStartedView()
                .tabItem {
                    Label(AppTab.home.title, systemImage: AppTab.home.systemImage)
                }
                .tag(AppTab.home)

            // ✍️ Compose SIF View
            CreateSIFView()
                .environmentObject(router)
                .environmentObject(authState)
                .tabItem {
                    Label(AppTab.compose.title, systemImage: AppTab.compose.systemImage)
                }
                .tag(AppTab.compose)


            // 👥 Connect View
            AllUsersView()
                .tabItem {
                    Label(AppTab.sifConnect.title, systemImage: AppTab.sifConnect.systemImage)
                }
                .tag(AppTab.sifConnect)

            // 👤 Profile View
            ProfileView()
                .environmentObject(authState)
                .tabItem {
                    Label(AppTab.profile.title, systemImage: AppTab.profile.systemImage)
                }
                .tag(AppTab.profile)
        }
        .accentColor(Color(hex: "132E37"))
        .environmentObject(router)
        .environmentObject(authState)
    }
}

#Preview {
    MainTabView()
}
