import SwiftUI
import FirebaseAuth

struct ForgotPasswordView: View {
    @State private var email = ""
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isLoading = false

    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            // MARK: - Background
            GradientTheme.welcomeBackground
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer(minLength: 40)

                // MARK: - Header
                VStack(spacing: 10) {
                    Image("isiFLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .shadow(color: .black.opacity(0.25), radius: 6, y: 4)

                    Text("Forgot Password?")
                        .font(TextStyles.title(28))
                        .foregroundColor(.black.opacity(0.85))

                    Text("We’ll send a reset link to your registered email.")
                        .font(TextStyles.subtitle(15))
                        .foregroundColor(.black.opacity(0.65))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }

                // MARK: - Card
                ZStack {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color.white.opacity(0.96))
                        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)

                    VStack(spacing: 18) {
                        CapsuleField(placeholder: "Email Address", text: $email)

                        Button(action: handlePasswordReset) {
                            HStack(spacing: 8) {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Send Reset Link")
                                    Image(systemName: "paperplane.fill")
                                }
                            }
                            .font(TextStyles.subtitle(17))
                            .foregroundColor(.white)
                            .padding(.vertical, 14)
                            .frame(maxWidth: .infinity)
                            .background(
                                Capsule()
                                    .fill(GradientTheme.primaryPill)
                                    .shadow(color: .black.opacity(0.25), radius: 5, y: 4)
                            )
                        }
                        .disabled(isLoading)
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }
                .padding(.horizontal, 28)

                // MARK: - Back Button
                Button(action: { dismiss() }) {
                    Text("Back to Login")
                        .font(TextStyles.subtitle(15))
                        .foregroundColor(.black.opacity(0.7))
                        .underline()
                }
                .padding(.top, 16)

                Spacer(minLength: 40)
            }
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK", role: .cancel) { dismiss() }
        } message: {
            Text(alertMessage)
        }
        .navigationBarHidden(true)
    }

    // MARK: - Handle Password Reset
    private func handlePasswordReset() {
        guard !email.isEmpty else {
            alertTitle = "Missing Email"
            alertMessage = "Please enter your email address."
            showingAlert = true
            return
        }

        isLoading = true
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            DispatchQueue.main.async {
                isLoading = false
            }

            if let error = error {
                alertTitle = "Error"
                alertMessage = error.localizedDescription
                showingAlert = true
                return
            }

            alertTitle = "Email Sent"
            alertMessage = "Check your inbox for a password reset link."
            showingAlert = true
        }
    }
}
