import SwiftUI
import FirebaseAuth

struct ChangePasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmNewPassword = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        ZStack {
            GradientTheme.welcomeBackground
                .ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer(minLength: 40)

                // MARK: - Title
                Text("Change Password")
                    .font(TextStyles.title(28))
                    .foregroundColor(.black.opacity(0.85))

                // MARK: - Frosted Glass Password Card
                FrostedRoundedCard {
                    VStack(spacing: 18) {
                        CapsuleField(placeholder: "Current Password", text: $currentPassword, secure: true)
                        CapsuleField(placeholder: "New Password", text: $newPassword, secure: true)
                        CapsuleField(placeholder: "Confirm New Password", text: $confirmNewPassword, secure: true)

                        Button(action: changePassword) {
                            Text("Update Password")
                                .font(TextStyles.subtitle(17))
                                .foregroundColor(.white)
                                .padding(.vertical, 14)
                                .frame(maxWidth: .infinity)
                                .background(
                                    Capsule()
                                        .fill(GradientTheme.primaryPill)
                                        .shadow(color: .black.opacity(0.25), radius: 4, y: 3)
                                )
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 24)
                }
                .padding(.horizontal, 32)

                Spacer()
            }
            .padding(.horizontal, 16)
        }
        .alert("Password Update", isPresented: $showingAlert) {
            Button("OK") { dismiss() }
        } message: {
            Text(alertMessage)
        }
    }

    // MARK: - Password Update Logic
    private func changePassword() {
        guard !currentPassword.isEmpty, !newPassword.isEmpty, !confirmNewPassword.isEmpty else {
            alertMessage = "Please fill in all fields."
            showingAlert = true
            return
        }

        guard newPassword == confirmNewPassword else {
            alertMessage = "New passwords do not match."
            showingAlert = true
            return
        }

        guard let user = Auth.auth().currentUser,
              let email = user.email else {
            alertMessage = "No active user session found."
            showingAlert = true
            return
        }

        // 🔐 Reauthenticate before password change
        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
        user.reauthenticate(with: credential) { _, error in
            if let error = error {
                alertMessage = "Reauthentication failed: \(error.localizedDescription)"
                showingAlert = true
                return
            }

            user.updatePassword(to: newPassword) { error in
                if let error = error {
                    alertMessage = "Password update failed: \(error.localizedDescription)"
                } else {
                    alertMessage = "✅ Password successfully updated."
                }
                showingAlert = true
            }
        }
    }
}

#Preview {
    ChangePasswordView()
        .environmentObject(AuthState())
}
