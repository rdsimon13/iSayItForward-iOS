// ✅ SignupView.swift
import SwiftUI

struct SignupView: View {
    @StateObject private var authManager = AuthenticationManager()
    @Environment(\.presentationMode) var presentationMode
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color.mainAppGradient.ignoresSafeArea()

                VStack(spacing: 20) {
                    Text("Create Account")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom, 30)
                        .foregroundColor(.white)

                    // Error Message
                    if let errorMessage = authManager.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    TextField("Your Name", text: $name)
                        .textFieldStyle(PillTextFieldStyle())
                        .disabled(authManager.isLoading)

                    TextField("Your Email", text: $email)
                        .textFieldStyle(PillTextFieldStyle())
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .disabled(authManager.isLoading)

                    SecureField("Create Password", text: $password)
                        .textFieldStyle(PillTextFieldStyle())
                        .disabled(authManager.isLoading)

                    SecureField("Confirm Password", text: $confirmPassword)
                        .textFieldStyle(PillTextFieldStyle())
                        .disabled(authManager.isLoading)

                    Spacer()

                    Button(action: {
                        handleSignup()
                    }) {
                        HStack {
                            if authManager.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Text("Sign Up")
                            }
                        }
                    }
                    .buttonStyle(PrimaryActionButtonStyle())
                    .disabled(authManager.isLoading || !isFormValid())
                }
                .padding(.horizontal, 32)
                .padding(.vertical)
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .onChange(of: authManager.isAuthenticated) { isAuthenticated in
                if isAuthenticated {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }

    private func isFormValid() -> Bool {
        return !name.isEmpty && 
               !email.isEmpty && 
               !password.isEmpty && 
               !confirmPassword.isEmpty &&
               password == confirmPassword &&
               password.count >= 6
    }

    private func handleSignup() {
        guard password == confirmPassword else {
            authManager.errorMessage = "Passwords do not match."
            return
        }
        
        authManager.clearError()
        Task {
            await authManager.signUp(email: email, password: password)
        }
    }
}
