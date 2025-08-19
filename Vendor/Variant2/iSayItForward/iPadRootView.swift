import SwiftUI

struct iPadRootView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject var authState: AuthState

    var body: some View {
        Group {
            if authState.isLoggedIn {
                if horizontalSizeClass == .regular {
                    iPadMainView()      // your iPad layout
                } else {
                    HomeView()          // your phone/home layout
                }
            } else {
                WelcomeView()
            }
        }
    }
}

struct iPadRootView_Previews: PreviewProvider {
    static var previews: some View {
        iPadRootView()
            .environmentObject(AuthState()) // <- supply for preview
            .previewInterfaceOrientation(.landscapeLeft)
    }
}
