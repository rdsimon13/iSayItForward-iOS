import SwiftUI

struct iPadRootView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject var authManager: AuthenticationManager

    var body: some View {
        if authManager.isAuthenticated {
            if horizontalSizeClass == .regular {
                iPadMainView()
            } else {
                HomeView()
            }
        } else {
            WelcomeView()
        }
    }
}
