import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authState: AuthState

    var body: some View {
        ZStack {
            if authState.isUserLoggedIn {
                DashboardView()
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else {
                WelcomeView()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.4), value: authState.isUserLoggedIn)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthState())
}
