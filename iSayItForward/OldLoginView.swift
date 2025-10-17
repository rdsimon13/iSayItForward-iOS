import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @EnvironmentObject var authState: AuthState
    @State private var email = ""
    @State private var password = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "#89e9ff"),
                    Color(hex: "#eefcff")
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 40)

                Image("isiFLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .shadow(color: .black.opacity(0.3), radius: 6, y: 4)
                    .padding(.bottom, 10)

                Text("Welcome Back")
                    .font(TextStyles.title(30))
                    .foregroundColor(.black.opacity(0.85))
                    .padding(.bottom, 20)

                ZStack {
                    RoundedRectangle(cornerRadius: 36)
                        .fill(Color.white.opacity(0.95))
                        .shadow(color: .black.opacity(0.15), radius: 10, y: 5)

                    VStack(spacing: 16) {
                        capsuleField(placeholder: "Email", text: $email)
                        capsuleField(placeholder: "Password", text: $password, isSecure: true)

                        // MARK: - Login Button
                        GradientCapsuleButton(
                            title: "Log In",
                            style: .primary,
                            isLoading: isLoading
                        ) {
                            handleLogin()
                        }

                        Button(action: {
                            print("Forgot password tapped")
                        }) {
                            Text("Forgot Password?")
                                .font(TextStyles.small(13))
                                .foregroundColor(.blue)
                        }
                        .padding(.top, 4)

                        Spacer().frame(height: 10)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .alert("Login", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }

    private func capsuleField(
        placeholder: String,
        text: Binding<String>,
        isSecure: Bool = false
    ) -> some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: text)
            } else {
                TextField(placeholder, text: text)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 18)
        .background(
            Capsule()
                .stroke(Color.black.opacity(0.25), lineWidth: 1)
                .background(Capsule().fill(Color.white.opacity(0.9)))
        )
        .font(TextStyles.body(15))
        .textInputAutocapitalization(.none)
    }

    private func handleLogin() {
        guard !email.isEmpty, !password.isEmpty else {
            alertMessage = "Please fill in both fields."
            showingAlert = true
            return
        }

        isLoading = true

        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            DispatchQueue.main.async {
                isLoading = false
            }

            if let error = error {
                alertMessage = error.localizedDescription
                showingAlert = true
                return
            }

            if result?.user != nil {
                DispatchQueue.main.async {
                    authState.isUserLoggedIn = true
                }
            }
        }
    }
}
