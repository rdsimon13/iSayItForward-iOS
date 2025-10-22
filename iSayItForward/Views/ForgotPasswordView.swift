import SwiftUI
import FirebaseAuth

struct ForgotPasswordView: View {
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var alertMessage = ""
    @State private var showingAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.0, green: 0.8118, blue: 1.0),
                        Color(red: 1.0, green: 1.0, blue: 1.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 25) {
                    Text("Reset Password")
                        .font(.custom("Kodchasan-Bold", size: 26))
                        .foregroundColor(.white)
                        .padding(.top, 60)

                    Text("Enter your email address and we’ll send you a link to reset your password.")
                        .font(.custom("Kodchasan-Regular", size: 15))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.black.opacity(0.9))
                        .padding(.horizontal, 40)

                    TextField("Email Address", text: $email)
                        .textFieldStyle(PillTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding(.horizontal, 40)

                    Button(action: resetPassword) {
                        Text("Send Reset Link")
                            .font(.custom("Kodchasan-Bold", size: 18))
                            .foregroundColor(Color.black.opacity(0.8))
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(hex: "FFD700"))
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                    }
                    .padding(.horizontal, 40)

                    Button("Back to Sign In") {
                        dismiss()
                    }
                    .font(.custom("Kodchasan-Regular", size: 14))
                    .foregroundColor(.black.opacity(0.9))
                    .padding(.top, 20)

                    Spacer()
                }
            }
            .alert("Password Reset", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { dismiss() }
            } message: {
                Text(alertMessage)
            }
        }
    }

    private func resetPassword() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else {
            alertMessage = "Please enter your email address."
            showingAlert = true
            return
        }

        Auth.auth().sendPasswordReset(withEmail: trimmedEmail) { error in
            DispatchQueue.main.async {
                if let error = error {
                    alertMessage = "❌ \(error.localizedDescription)"
                } else {
                    alertMessage = "✅ Password reset email sent to \(trimmedEmail)"
                }
                showingAlert = true
            }
        }
    }
}
#Preview {
    ForgotPasswordView()
        .environmentObject(AuthState())
}
