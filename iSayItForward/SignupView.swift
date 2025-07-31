import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SignupView: View {
    var onSignup: ((User) -> Void)? = nil

    @Environment(\.presentationMode) var presentationMode
    @StateObject private var subscriptionManager = SubscriptionManager()
    
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isSigningUp = false
    @State private var showingTierSelection = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.mainAppGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            Text("Create Account")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.neutralGray800)
                            
                            Text("Join iSayItForward and start sharing your messages")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.neutralGray600)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 40)

                        // Form fields
                        VStack(spacing: 16) {
                            TextField("Your Name", text: $name)
                                .textFieldStyle(PillTextFieldStyle(iconName: "person.fill"))

                            TextField("Your Email", text: $email)
                                .textFieldStyle(PillTextFieldStyle(iconName: "envelope.fill"))
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)

                            SecureField("Create Password", text: $password)
                                .textFieldStyle(PillTextFieldStyle(iconName: "lock.fill"))
                        }

                        Spacer()

                        // Sign up button
                        VStack(spacing: 16) {
                            Button(action: handleSignup) {
                                HStack {
                                    if isSigningUp {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .foregroundColor(.white)
                                    }
                                    
                                    Text(isSigningUp ? "Creating Account..." : "Sign Up")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.brandBlue)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: .brandBlue.opacity(0.3), radius: 4, y: 2)
                            }
                            .disabled(isSigningUp || !isFormValid)
                            .opacity(isFormValid ? 1.0 : 0.6)
                            
                            Text("By signing up, you agree to our Terms of Service and Privacy Policy")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.neutralGray500)
                                .multilineTextAlignment(.center)
                        }
                        
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .alert("Signup Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $showingTierSelection) {
                TierSelectionView(isUpgradeFlow: false)
                    .environmentObject(subscriptionManager)
            }
        }
    }
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.isEmpty &&
        password.count >= 6 &&
        email.contains("@")
    }

    private func handleSignup() {
        guard isFormValid else {
            alertMessage = "Please fill out all fields correctly. Password must be at least 6 characters."
            showingAlert = true
            return
        }
        
        isSigningUp = true
        
        Task {
            do {
                // Create Firebase Auth user
                let result = try await Auth.auth().createUser(withEmail: email, password: password)
                
                // Create user object with default free tier
                let newUser = User(
                    uid: result.user.uid,
                    name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                    email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                    tier: .free
                )
                
                // Save to Firestore
                let success = await subscriptionManager.createUser(newUser)
                
                await MainActor.run {
                    isSigningUp = false
                    
                    if success {
                        print("✅ Successfully created user: \(newUser.name)")
                        onSignup?(newUser)
                        showingTierSelection = true
                    } else {
                        alertMessage = subscriptionManager.error ?? "Failed to create user profile"
                        showingAlert = true
                    }
                }
                
            } catch {
                await MainActor.run {
                    isSigningUp = false
                    alertMessage = "Failed to create account: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
}

struct SignupView_Previews: PreviewProvider {
    static var previews: some View {
        SignupView()
    }
}
