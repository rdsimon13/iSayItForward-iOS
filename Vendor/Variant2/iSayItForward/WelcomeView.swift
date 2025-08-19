import SwiftUI

struct WelcomeView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.vibrantGradient.ignoresSafeArea() // Use our new gradient

                VStack(spacing: 20) {
                    Spacer()

                    Image("isifLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .padding(.bottom, 20)

                    Text("Welcome to iSayItForward")
                        .font(.largeTitle.weight(.bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("The Ultimate Way to Express Yourself!")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)

                    Spacer()
                    Spacer()

                    VStack(spacing: 16) {
                        NavigationLink(destination: LoginView()) {
                            Text("Login")
                                .font(.headline.weight(.semibold))
                                .foregroundColor(Theme.textDark)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(.white)
                                .cornerRadius(12)
                        }

                        NavigationLink("Don't have an account? Sign up") {
                            // We will need to create a new SignupView that matches this style
                            SignupView()
                        }
                        .font(.footnote)
                        .foregroundColor(.white)
                    }
                    .padding(.bottom, 40)
                }
                .padding(.horizontal, 32)
            }
        }
    }
}
