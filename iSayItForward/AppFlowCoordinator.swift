import SwiftUI

struct AppFlowCoordinator: View {
    @EnvironmentObject var authState: AuthState
    @State private var currentRoute: AppRoute = .welcome
    @Namespace private var transitionNamespace
    @State private var navigationPath = NavigationPath()
    @State private var isTransitioning = false

    var body: some View {
        ZStack {
            switch currentRoute {
            case .welcome:
                WelcomeView()
                    .environmentObject(authState)
                    .matchedGeometryEffect(id: "screen", in: transitionNamespace)
                    .transition(.opacity.combined(with: .move(edge: .trailing)))

            case .compose:
                ComposeSIFView()
                    .environmentObject(authState)
                    .matchedGeometryEffect(id: "screen", in: transitionNamespace)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .trailing)),
                        removal: .opacity.combined(with: .move(edge: .leading))
                    ))

            case .confirm:
                SIFConfirmView()
                    .environmentObject(authState)
                    .matchedGeometryEffect(id: "screen", in: transitionNamespace)
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
        }
        .animation(.easeInOut(duration: 0.55), value: currentRoute)
        .onChange(of: authState.isUserLoggedIn) { loggedIn in
            withAnimation {
                currentRoute = loggedIn ? .compose : .welcome
            }
        }
        .environment(\.appRoute, $currentRoute)
    }
}
