import SwiftUI

struct AppFlowCoordinator: View {
    @EnvironmentObject var authState: AuthState
    @EnvironmentObject var router: TabRouter

    var body: some View {
        NavigationStack {
            switch router.selectedTab {
            case .home:
                DashboardView()
            case .compose:
                CreateSIFView()
            case .profile:
                ProfileView()
            case .schedule:
                ScheduleSIFView()
            case .gallery:
                TemplateGalleryView(selectedTemplate: .constant(nil))
            case .settings:
                SettingsView()
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}
