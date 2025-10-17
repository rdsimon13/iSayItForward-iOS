import SwiftUI
import FirebaseAuth

struct SignupView: View {
    // MARK: - Environment & State
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authState: AuthState

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false

    var body: some View {
        ZStack {
            // MARK: Background
            GradientTheme.welcomeBackground
                .ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer(minLength: 40)

                // MARK: Header
                VStack(spacing: 12) {
                    Image("isiFLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .shadow(color: .black.opacity(0.3), radius: 5, y: 3)

                    OutlinedText(
                        text: "iSayItForward",
                        font: TextStyles.title(36),
                        fillColor: Color(red: 0.92, green: 0.96, blue: 0.98),
                        strokeColor: Color(red: 0.07, green: 0.18, blue: 0.22),
                        outlineWidth: 0.8,
                        shadowColor: .black,
                        shadowRadius: 3,
                        tracking: 2
                    )

                    OutlinedText(
                        text: "The Ultimate Way to Express Yourself",
                        font: TextStyles.subtitle(15),
                        fillColor: Color(red: 0.9, green: 0.95, blue: 0.96),
                        strokeColor: Color(red: 0.07, green: 0.18, blue: 0.22),
                        outlineWidth: 0.5,
                        shadowColor: .black.opacity(0.6),
                        shadowRadius: 1.5,
                        tracking: 1.2
                    )
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 4)
                }

                // MARK: - Form Card
                VStack(spacing: 16) {
                    Text("Create Your Free Account")
                        .font(TextStyles.subtitle(20))
                        .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
                        .tracking(1.4)

                    HStack(spacing: 10) {
                        CapsuleField(placeholder: "First Name", text: $firstName)
                        CapsuleField(placeholder: "Last Name", text: $lastName)
                    }

                    CapsuleField(placeholder: "Email or Phone Number", text: $email)
                    CapsuleField(placeholder: "Create Password", text: $password, secure: true)
                    CapsuleField(placeholder: "Confirm Password", text: $confirmPassword, secure: true)

                    // MARK: - Sign Up Button
                    Button(action: handleSignup) {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Capsule().fill(GradientTheme.goldPill))
                                .shadow(color: .black.opacity(0.3), radius: 5, y: 3)
                        } else {
                            Text("Sign Up")
                                .font(TextStyles.subtitle(18))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Capsule().fill(GradientTheme.goldPill))
                                .shadow(color: .black.opacity(0.3), radius: 5, y: 3)
                        }
                    }
                    .padding(.top, 8)

                    // MARK: - Divider
                    VStack(spacing: 10) {
                        Text("Or Sign Up With")
                            .font(TextStyles.body(14))
                            .foregroundColor(.black.opacity(0.75))
                            .tracking(1.1)

                        HStack(spacing: 22) {
                            SocialLoginButton(imageName: "googleLogo", systemFallback: "g.circle.fill") {
                                print("🔵 Google Sign Up tapped")
                            }
                            SocialLoginButton(imageName: "appleLogo", systemFallback: "applelogo") {
                                print("⚫️ Apple Sign Up tapped")
                            }
                        }
                    }
                    .padding(.top, 8)

                    // MARK: - Terms
                    Text("By signing up, you agree to our Terms of Service")
                        .font(TextStyles.small(12))
                        .foregroundColor(.black.opacity(0.6))
                        .tracking(1)
                        .multilineTextAlignment(.center)
                        .padding(.top, 12)
                }
                .padding(.horizontal, 36)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .fill(Color.white.opacity(0.92))
                        .shadow(color: .black.opacity(0.25), radius: 6, y: 4)
                )

                Spacer(minLength: 20)
            }
            .padding(.horizontal, 16)
        }
        // MARK: Alert
        .alert("Sign Up Failed", isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    // MARK: - Signup Logic
    private func handleSignup() {
        guard !firstName.isEmpty,
              !lastName.isEmpty,
              !email.isEmpty,
              !password.isEmpty,
              !confirmPassword.isEmpty else {
            alertMessage = "Please fill in all fields."
            showingAlert = true
            return
        }

        guard password == confirmPassword else {
            alertMessage = "Passwords do not match."
            showingAlert = true
            return
        }

        isLoading = true

        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            DispatchQueue.main.async {
                isLoading = false
            }

            if let error = error {
                alertMessage = error.localizedDescription
                showingAlert = true
                return
            }

            if let _ = result?.user {
                print("✅ Sign Up successful.")
                DispatchQueue.main.async {
                    authState.isUserLoggedIn = true
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    SignupView()
        .environmentObject(AuthState())
}
