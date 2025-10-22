import SwiftUI

struct AppFlowCoordinator: View {
    @EnvironmentObject var authState: AuthState
    @Namespace private var transitionNamespace

    @State private var currentRoute: AppRoute = .welcome
    @State private var navigationPath = NavigationPath()
    @State private var isTransitioning = false

    var body: some View {
        ZStack {
            if authState.isUserLoggedIn {
                // ✅ Replace with your actual app dashboard
                DashboardView()
                    .transition(.opacity)
                    .matchedGeometryEffect(id: "screen", in: transitionNamespace)
            } else {
                WelcomeView()
                    .transition(.opacity)
                    .matchedGeometryEffect(id: "screen", in: transitionNamespace)
            }
        }
        .animation(.easeInOut, value: authState.isUserLoggedIn)
        .onAppear {
            print("🌐 AppFlowCoordinator sees AuthState instance → \(Unmanaged.passUnretained(authState).toOpaque())")
        }
    }
}
