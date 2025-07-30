import SwiftUI

struct iPadRootView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject var authState: AuthState

    var body: some View {
        if authState.isUserLoggedIn {
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
