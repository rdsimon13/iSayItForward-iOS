import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showingSignupSheet = false
    @State private var showingLoginSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mainAppGradient.ignoresSafeArea()

                VStack(spacing: 20) {
                    Spacer()

                    Image("isifLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 96, height: 96)

                    Text("iSayItForward")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color.brandDarkBlue)

                    Text("The Ultimate Way to Express Yourself")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Spacer()

                    Button("Sign In") {
                        showingLoginSheet = true
                    }
                    .buttonStyle(SecondaryActionButtonStyle())

                    Button("Create New Account") {
                        showingSignupSheet = true
                    }
                    .buttonStyle(PrimaryActionButtonStyle())

                    Text("By signing up, you agree to our Terms of Service")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)
                .sheet(isPresented: $showingSignupSheet) {
                    SignupView()
                }
                .sheet(isPresented: $showingLoginSheet) {
                    LoginView()
                }
            }
        }
    }
}
