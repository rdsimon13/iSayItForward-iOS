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
        NavigationStack {
            ZStack {
                // MARK: - Background Gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.0, green: 0.8118, blue: 1.0),
                        Color.white
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 25) {
                    // MARK: - Title
                    Text("Change Password")
                        .font(.custom("Kodchasan-Bold", size: 26))
                        .foregroundColor(.white)
                        .padding(.top, 60)

                    Text("Enter your current password and your new password below.")
                        .font(.custom("Kodchasan-Regular", size: 15))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.black.opacity(0.9))
                        .padding(.horizontal, 40)

                    // MARK: - Input Fields
                    VStack(spacing: 18) {
                        SecureField("Current Password", text: $currentPassword)
                            .textFieldStyle(PillTextFieldStyle())
                            .autocapitalization(.none)

                        SecureField("New Password", text: $newPassword)
                            .textFieldStyle(PillTextFieldStyle())
                            .autocapitalization(.none)

                        SecureField("Confirm New Password", text: $confirmNewPassword)
                            .textFieldStyle(PillTextFieldStyle())
                            .autocapitalization(.none)
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 10)

                    // MARK: - Update Button
                    Button(action: changePassword) {
                        Text("Update Password")
                            .font(.custom("Kodchasan-Bold", size: 18))
                            .foregroundColor(Color.black.opacity(0.85))
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(hex: "FFD700"))
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 10)

                    // MARK: - Back Button
                    Button("Back to Profile") {
                        dismiss()
                    }
                    .font(.custom("Kodchasan-Regular", size: 14))
                    .foregroundColor(.black.opacity(0.9))
                    .padding(.top, 15)

                    Spacer()
                }
            }
            .alert("Password Update", isPresented: $showingAlert) {
                Button("OK") { dismiss() }
            } message: {
                Text(alertMessage)
            }
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
