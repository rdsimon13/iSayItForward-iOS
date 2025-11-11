import SwiftUI

struct NavigationHostView: View {
    @EnvironmentObject var router: TabRouter
    @EnvironmentObject var authState: AuthState

    var body: some View {
        ZStack {
            switch router.selectedTab {
            case .home:
                DashboardView()
                    .environmentObject(router)
                    .environmentObject(authState)

            case .compose:
                CreateSIFView()
                    .environmentObject(router)
                    .environmentObject(authState)

            case .gallery:
                TemplateGalleryView(selectedTemplate: .constant(nil))
                    .environmentObject(router)
                    .environmentObject(authState)

            case .schedule:
                ScheduleSIFView()
                    .environmentObject(router)
                    .environmentObject(authState)

            case .profile:
                ProfileView()
                    .environmentObject(router)
                    .environmentObject(authState)

            case .settings:
                SettingsView()
                    .environmentObject(router)
                    .environmentObject(authState)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: router.selectedTab)
    }
}
