import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @StateObject private var authManager = AuthenticationManager()
    @State private var email = ""
    @State private var password = ""
    @State private var showSignUp = false
    @State private var showPasswordReset = false
    @State private var resetEmail = ""
    @State private var showingPasswordResetAlert = false

    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                ZStack {
                    Color.mainAppGradient.ignoresSafeArea()

                    VStack(spacing: 20) {
                        Text("iSayItForward")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Login to Your Account")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        // Error Message
                        if let errorMessage = authManager.errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        TextField("Email", text: $email)
                            .textFieldStyle(PillTextFieldStyle())
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .disabled(authManager.isLoading)

                        SecureField("Password", text: $password)
                            .textFieldStyle(PillTextFieldStyle())
                            .disabled(authManager.isLoading)

                        // Email/Password Login Button
                        Button(action: {
                            authManager.clearError()
                            Task {
                                await authManager.signIn(email: email, password: password)
                            }
                        }) {
                            HStack {
                                if authManager.isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Login")
                                }
                            }
                        }
                        .buttonStyle(SecondaryActionButtonStyle())
                        .disabled(authManager.isLoading || email.isEmpty || password.isEmpty)
                        .padding(.top)

                        // Password Reset Link
                        Button("Forgot Password?") {
                            showPasswordReset = true
                        }
                        .font(.footnote)
                        .foregroundColor(.blue)

                        // Divider
                        HStack {
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(.gray.opacity(0.3))
                            Text("OR")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(.gray.opacity(0.3))
                        }
                        .padding(.vertical)

                        // Google Sign In Button
                        Button(action: {
                            authManager.clearError()
                            Task {
                                await authManager.signInWithGoogle()
                            }
                        }) {
                            HStack {
                                Image(systemName: "globe")
                                Text("Continue with Google")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.black)
                            .cornerRadius(25)
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .disabled(authManager.isLoading)

                        // Apple Sign In Button
                        SignInWithAppleButton(
                            onRequest: { request in
                                request.requestedScopes = [.fullName, .email]
                            },
                            onCompletion: { result in
                                // Handle Apple Sign In result
                                switch result {
                                case .success:
                                    // This will be handled by the ASAuthorizationControllerDelegate
                                    break
                                case .failure:
                                    authManager.errorMessage = "Apple Sign In failed. Please try again."
                                }
                            }
                        )
                        .frame(height: 50)
                        .cornerRadius(25)

                        NavigationLink("Don't have an account? Sign up") {
                            SignupView()
                        }
                        .font(.footnote)
                        .padding(.top)
                    }
                    .padding(.horizontal, 32)
                    .navigationDestination(isPresented: $authManager.isAuthenticated) {
                        HomeView()
                    }
                }
            }
            .alert("Password Reset", isPresented: $showPasswordReset) {
                TextField("Email", text: $resetEmail)
                Button("Send Reset Email") {
                    Task {
                        await authManager.resetPassword(email: resetEmail)
                        showingPasswordResetAlert = true
                    }
                }
                Button("Cancel", role: .cancel) {
                    resetEmail = ""
                }
            } message: {
                Text("Enter your email address to receive a password reset link.")
            }
            .alert("Password Reset", isPresented: $showingPasswordResetAlert) {
                Button("OK") {
                    resetEmail = ""
                }
            } message: {
                Text(authManager.errorMessage ?? "If an account with that email exists, a password reset link has been sent.")
            }
        } else {
            Text("iSayItForward requires iOS 16.0 or newer.")
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
                .padding()
        }
    }
}
