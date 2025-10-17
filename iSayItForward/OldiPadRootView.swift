import SwiftUI
import FirebaseAuth

struct iPadRootView: View {
    @EnvironmentObject var authState: AuthState
    @State private var isShowingSignup = false

    var body: some View {
        Group {
            if authState.isUserLoggedIn {
                DashboardView()
            } else {
                WelcomeFlowView(
                    onSignupTapped: { isShowingSignup = true },
                    onLoginTapped: { isShowingSignup = false }
                )
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authState.isUserLoggedIn)
    }
}

// MARK: - Welcome/Login/Signup Flow Container
struct WelcomeFlowView: View {
    var onSignupTapped: () -> Void
    var onLoginTapped: () -> Void

    @State private var showingSignup = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "#89e9ff"),
                    Color(hex: "#eefcff")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer(minLength: 40)

                Image("isiFLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .shadow(color: .black.opacity(0.25), radius: 6, y: 4)

                Text("iSayItForward")
                    .font(TextStyles.title(36))
                    .foregroundColor(.black.opacity(0.85))

                Text("The Ultimate Way to Express Yourself")
                    .font(TextStyles.subtitle(16))
                    .foregroundColor(.black.opacity(0.65))
                    .padding(.bottom, 24)

                // MARK: - Switch between Signup and Login
                if showingSignup {
                    SignupView()
                        .transition(.move(edge: .trailing))
                } else {
                    LoginView()
                        .transition(.move(edge: .leading))
                }

                Spacer()

                HStack {
                    Text(showingSignup ? "Already have an account?" : "Don't have an account?")
                        .font(TextStyles.small(13))
                        .foregroundColor(.black.opacity(0.7))

                    Button(action: {
                        withAnimation {
                            showingSignup.toggle()
                        }
                    }) {
                        Text(showingSignup ? "Log In" : "Sign Up")
                            .font(TextStyles.small(13))
                            .foregroundColor(.blue)
                            .fontWeight(.semibold)
                    }
                }
                .padding(.bottom, 30)
            }
            .padding(.horizontal, 30)
        }
    }
}
