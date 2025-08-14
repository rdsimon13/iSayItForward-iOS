import SwiftUI

struct AppBackground: View {
    @EnvironmentObject var authState: AuthState
    
    var body: some View {
        ZStack {
            // Safe to use auth state here since Firebase is initialized in AppDelegate
            if authState.isLoggedIn {
                // Authenticated background
                Color("BackgroundColor")
                    .ignoresSafeArea()
            } else {
                // Non-authenticated background
                Color("BackgroundColor")
                    .ignoresSafeArea()
            }
        }
    }
}
