import SwiftUI
import FirebaseAuth

struct SignupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.vibrantGradient.ignoresSafeArea() // Use our new gradient

                ScrollView {
                    VStack(spacing: 24) {
                        Image("isifLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 50)
                            .padding(.top, 50)

                        Text("Create Your Account")
                            .font(.title.weight(.bold))
                            .foregroundColor(.white)

                        // --- Form Fields with Frosted Glass Style ---
                        VStack(spacing: 16) {
                            TextField("Your Name", text: $name)
                                .textContentType(.name)
                            
                            Divider().background(Color.white.opacity(0.5))

                            TextField("Your Email", text: $email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                            
                            Divider().background(Color.white.opacity(0.5))

                            SecureField("Create Password", text: $password)
                                .textContentType(.newPassword)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(.white.opacity(0.2))
                        .cornerRadius(12)
                        
                        Button("Sign Up") {
                            handleSignup()
                        }
                        .buttonStyle(PrimaryButtonStyle()) // Use our updated button style
                    }
                    .padding(.horizontal, 32)
                }
            }
            .navigationBarHidden(true)
            .alert("Sign Up Error", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }

    private func handleSignup() {
        guard !name.isEmpty, !email.isEmpty, !password.isEmpty else {
            alertMessage = "Please fill out all fields."
            showingAlert = true
            return
        }
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                alertMessage = error.localizedDescription
                showingAlert = true
                return
            }
            dismiss()
        }
    }
}
