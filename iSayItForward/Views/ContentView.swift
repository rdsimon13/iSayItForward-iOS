import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authState: AuthState

    var body: some View {
        Group {
            if authState.isUserLoggedIn {
                DashboardView()
            } else {
                WelcomeView()
            }
        }
        .animation(.easeInOut, value: authState.isUserLoggedIn)
        .transition(.opacity)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthState())
}
