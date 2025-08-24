import SwiftUI
import FirebaseAuth

struct WelcomeView: View {
    @StateObject private var subscriptionManager = SubscriptionManager()
    @EnvironmentObject var authState: AuthState
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showingSignupSheet = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isSigningIn = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mainAppGradient.ignoresSafeArea()

                if authState.isUserLoggedIn {
                    HomeView()
                        .environmentObject(subscriptionManager)
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            Spacer(minLength: 60)

                            // Logo and branding
                            VStack(spacing: 16) {
                                ModernCard(backgroundColor: .white, shadowRadius: 8) {
                                    Image("isifLogo")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 80, height: 80)
                                        .padding(20)
                                }
                                .frame(width: 120, height: 120)

                                VStack(spacing: 8) {
                                    Text("iSayItForward")
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .foregroundColor(.neutralGray800)

                                    Text("The Ultimate Way to Express Yourself")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.neutralGray600)
                                        .multilineTextAlignment(.center)
                                }
                            }

                            // Sign in form
                            ModernCard {
                                VStack(spacing: 20) {
                                    Text("Welcome Back")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.neutralGray800)

                                    VStack(spacing: 16) {
                                        TextField("Email or Phone Number", text: $email)
                                            .textFieldStyle(ModernTextFieldStyle(iconName: "envelope.fill"))
                                            .autocapitalization(.none)
                                            .keyboardType(.emailAddress)

                                        SecureField("Enter Password", text: $password)
                                            .textFieldStyle(ModernTextFieldStyle(iconName: "lock.fill", isSecure: true))
                                    }

                                    Button(action: handleSignIn) {
                                        HStack {
                                            if isSigningIn {
                                                ProgressView()
                                                    .scaleEffect(0.8)
                                                    .foregroundColor(.white)
                                            }
                                            
                                            Text(isSigningIn ? "Signing In..." : "Sign In")
                                                .font(.system(size: 16, weight: .semibold))
                                        }
                                    }
                                    .buttonStyle(ModernPrimaryButtonStyle(isEnabled: !isSigningIn && isFormValid))
                                    .disabled(isSigningIn || !isFormValid)

                                    Button("Forgot Password?") {
                                        handleForgotPassword()
                                    }
                                    .buttonStyle(ModernTertiaryButtonStyle())
                                    .font(.system(size: 14, weight: .medium))
                                }
                                .padding(24)
                            }

                            // Sign up section
                            VStack(spacing: 16) {
                                Text("New to iSayItForward?")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.neutralGray600)

                                Button("Create New Account") {
                                    showingSignupSheet = true
                                }
                                .buttonStyle(ModernSecondaryButtonStyle())
                            }

                            // Terms
                            Text("By signing in, you agree to our Terms of Service and Privacy Policy")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.neutralGray500)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)

                            Spacer(minLength: 40)
                        }
                        .padding(.horizontal, 24)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingSignupSheet) {
                SignupView { user in
                    showingSignupSheet = false
                    // User will be automatically signed in through Firebase Auth
                }
                .environmentObject(subscriptionManager)
            }
            .alert("Sign In Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private var isFormValid: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.isEmpty &&
        email.contains("@")
    }
    
    private func handleSignIn() {
        guard isFormValid else {
            alertMessage = "Please enter a valid email and password."
            showingAlert = true
            return
        }
        
        isSigningIn = true
        
        Task {
            do {
                let result = try await Auth.auth().signIn(withEmail: email, password: password)
                
                // Fetch user data from Firestore
                await subscriptionManager.fetchUserData(uid: result.user.uid)
                
                await MainActor.run {
                    isSigningIn = false
                    // AuthState will automatically update through the listener
                }
                
            } catch {
                await MainActor.run {
                    isSigningIn = false
                    alertMessage = "Failed to sign in: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
    
    private func handleForgotPassword() {
        guard !email.isEmpty, email.contains("@") else {
            alertMessage = "Please enter your email address first."
            showingAlert = true
            return
        }
        
        Task {
            do {
                try await Auth.auth().sendPasswordReset(withEmail: email)
                await MainActor.run {
                    alertMessage = "Password reset email sent to \(email)"
                    showingAlert = true
                }
            } catch {
                await MainActor.run {
                    alertMessage = "Failed to send password reset: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
            .environmentObject(AuthState())
    }
}
