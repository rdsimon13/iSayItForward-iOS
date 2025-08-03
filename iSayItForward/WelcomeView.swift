import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var authState: AuthState
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showingSignupSheet = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var currentUser: AppUser?
    @State private var emailValidationError: String?
    @State private var passwordValidationError: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mainAppGradient.ignoresSafeArea()

                VStack(spacing: 20) {
                    Spacer()

                    // Logo with subtle animation and fallback
                    Group {
                        if UIImage(named: "isifLogo") != nil {
                            Image("isifLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 96, height: 96)
                        } else {
                            // Fallback if logo is missing
                            ZStack {
                                Circle()
                                    .fill(Color.brandDarkBlue)
                                    .frame(width: 96, height: 96)
                                Text("iSIF")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .accessibilityLabel("iSayItForward app logo")

                    Text("iSayItForward")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color.brandDarkBlue)

                    Text("The Ultimate Way to Express Yourself")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text("Sign In or Register")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.top)
                        .foregroundColor(Color.brandDarkBlue)

                    // Email Field with Validation
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Email or Phone Number", text: $email)
                            .textFieldStyle(EnhancedPillTextFieldStyle(isError: emailValidationError != nil))
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .onChange(of: email) { _ in
                                validateEmail()
                            }
                            .accessibilityLabel("Email address input")
                        
                        if let error = emailValidationError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.leading, 16)
                                .accessibilityLabel("Email validation error: \(error)")
                        }
                    }

                    // Password Field with Validation
                    VStack(alignment: .leading, spacing: 4) {
                        SecureField("Enter Password", text: $password)
                            .textFieldStyle(EnhancedPillTextFieldStyle(isError: passwordValidationError != nil))
                            .onChange(of: password) { _ in
                                validatePassword()
                            }
                            .accessibilityLabel("Password input")
                        
                        if let error = passwordValidationError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.leading, 16)
                                .accessibilityLabel("Password validation error: \(error)")
                        }
                    }

                    // Sign In Button with Loading State
                    Button(action: handleSignIn) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                            Text(isLoading ? "Signing In..." : "Sign In")
                        }
                    }
                    .buttonStyle(EnhancedSecondaryActionButtonStyle())
                    .disabled(isLoading || !isFormValid)
                    .accessibilityLabel(isLoading ? "Signing in, please wait" : "Sign in to your account")

                    Button("Forgot Password?") {
                        alertMessage = "Password reset is unavailable in demo mode."
                        showingAlert = true
                        triggerHapticFeedback()
                    }
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding(.top, -10)

                    Spacer()

                    Text("Sign In With")
                        .font(.footnote)
                        .foregroundColor(.secondary)

                    HStack(spacing: 25) {
                        Image(systemName: "lock.slash")
                            .font(.system(size: 30))
                            .foregroundColor(.gray)
                    }
                    .frame(height: 50)

                    Button("Create New Account") {
                        showingSignupSheet = true
                        triggerHapticFeedback()
                    }
                    .buttonStyle(EnhancedPrimaryActionButtonStyle())
                    .disabled(isLoading)
                    .accessibilityLabel("Create a new account")

                    Text("By signing up, you agree to our Terms of Service")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)
                .disabled(isLoading)
                .sheet(isPresented: $showingSignupSheet) {
                    EnhancedSignupView { user in
                        authState.signInDemo(email: user.email, name: user.name)
                        showingSignupSheet = false
                    }
                }
                .alert(isPresented: $showingAlert) {
                    Alert(
                        title: Text("Notice"), 
                        message: Text(alertMessage), 
                        dismissButton: .default(Text("OK"))
                    )
                }

                // Navigation to HomeView
                NavigationLink(
                    destination: enhancedHomeView(),
                    isActive: $authState.isUserLoggedIn
                ) {
                    EmptyView()
                }
            }
        }
        .onAppear {
            print("✅ [WelcomeView] View appeared")
        }
    }
    
    // MARK: - Private Methods
    
    private var isFormValid: Bool {
        !email.isEmpty && 
        !password.isEmpty && 
        emailValidationError == nil && 
        passwordValidationError == nil
    }
    
    private func validateEmail() {
        emailValidationError = nil
        
        guard !email.isEmpty else { return }
        
        if email.count < 3 {
            emailValidationError = "Email is too short"
            return
        }
        
        // Basic email validation
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        if !emailPredicate.evaluate(with: email) && !email.contains("@") {
            emailValidationError = "Please enter a valid email address"
        }
    }
    
    private func validatePassword() {
        passwordValidationError = nil
        
        guard !password.isEmpty else { return }
        
        if password.count < 6 {
            passwordValidationError = "Password must be at least 6 characters"
        }
    }
    
    private func handleSignIn() {
        guard isFormValid else {
            triggerHapticFeedback(.error)
            return
        }
        
        isLoading = true
        triggerHapticFeedback(.selection)
        
        // Simulate authentication delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isLoading = false
            
            // Demo authentication - always succeeds
            authState.signInDemo(email: email, name: "Damon Sims")
            print("✅ [WelcomeView] Demo sign in successful for: \(email)")
            
            triggerHapticFeedback(.success)
        }
    }
    
    private func navigateToHome() {
        // Navigation is now handled by AuthState.isUserLoggedIn binding
        print("🏠 [WelcomeView] Navigating to home")
    }
    
    private func triggerHapticFeedback(_ type: UINotificationFeedbackGenerator.FeedbackType = .selection) {
        let impactFeedback = UINotificationFeedbackGenerator()
        impactFeedback.notificationOccurred(type)
    }
    
    @ViewBuilder
    private func enhancedHomeView() -> some View {
        if #available(iOS 16.0, *) {
            HomeView()
        } else {
            // Fallback for iOS 15
            LegacyHomeView()
        }
    }
}

// MARK: - Enhanced Signup View
private struct EnhancedSignupView: View {
    var onSignup: ((AppUser) -> Void)? = nil

    @Environment(\.presentationMode) var presentationMode
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var nameError: String?
    @State private var emailError: String?
    @State private var passwordError: String?

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

                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Your Name", text: $name)
                            .textFieldStyle(EnhancedPillTextFieldStyle(isError: nameError != nil))
                            .onChange(of: name) { _ in validateName() }
                            .accessibilityLabel("Full name input")
                        
                        if let error = nameError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.leading, 16)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Your Email", text: $email)
                            .textFieldStyle(EnhancedPillTextFieldStyle(isError: emailError != nil))
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .onChange(of: email) { _ in validateEmail() }
                            .accessibilityLabel("Email address input")
                        
                        if let error = emailError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.leading, 16)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        SecureField("Create Password", text: $password)
                            .textFieldStyle(EnhancedPillTextFieldStyle(isError: passwordError != nil))
                            .onChange(of: password) { _ in validatePassword() }
                            .accessibilityLabel("Password input")
                        
                        if let error = passwordError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.leading, 16)
                        }
                    }

                    Spacer()

                    Button(action: handleSignup) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                            Text(isLoading ? "Creating Account..." : "Sign Up")
                        }
                    }
                    .buttonStyle(EnhancedPrimaryActionButtonStyle())
                    .disabled(isLoading || !isFormValid)
                    .accessibilityLabel(isLoading ? "Creating account, please wait" : "Create your account")
                }
                .padding(.horizontal, 32)
                .padding(.vertical)
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("Sign Up Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    private var isFormValid: Bool {
        !name.isEmpty && !email.isEmpty && !password.isEmpty &&
        nameError == nil && emailError == nil && passwordError == nil
    }
    
    private func validateName() {
        nameError = name.count < 2 && !name.isEmpty ? "Name must be at least 2 characters" : nil
    }
    
    private func validateEmail() {
        guard !email.isEmpty else { 
            emailError = nil
            return 
        }
        
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        emailError = emailPredicate.evaluate(with: email) ? nil : "Please enter a valid email address"
    }
    
    private func validatePassword() {
        guard !password.isEmpty else {
            passwordError = nil
            return
        }
        
        passwordError = password.count >= 6 ? nil : "Password must be at least 6 characters"
    }

    private func handleSignup() {
        guard isFormValid else { return }
        
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isLoading = false
            let newUser = AppUser(uid: "demoUID", name: name, email: email)
            print("✅ [Demo Mode] Signed up user: \(newUser.name)")
            onSignup?(newUser)
            presentationMode.wrappedValue.dismiss()
        }
    }
}
