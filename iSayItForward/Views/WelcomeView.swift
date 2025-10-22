import SwiftUI
import FirebaseAuth

// MARK: - Gradient Foreground Extension (Assuming this is in a global file)
// extension View { ... }

// MARK: - Welcome View
struct WelcomeView: View {
    @EnvironmentObject var authState: AuthState

    @State private var email = ""
    @State private var password = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingSignupSheet = false

    // Colors for text styling
    let titleFillColor = Color(hex: "E6F4F5")
    let titleStrokeColor = Color(hex: "132E37")
    let buttonBackgroundColor = Color(hex: "132E37")
    let goldButtonColor = Color(hex: "FFD700")
    let primaryTextColor = Color.black.opacity(0.75)

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient // Use computed property

                ScrollView {
                    VStack(spacing: 20) {
                        headerSection      // Use computed property
                        signInForm         // Use computed property
                        socialLoginSection // Use computed property
                        createAccountButton // Use computed property
                        footerSection      // Use computed property
                    }
                }
            }
            .navigationBarHidden(true)
            .alert("Login Failed", isPresented: $showingAlert) { Button("OK") {} } message: { Text(alertMessage) }
        }
    }

    // MARK: - Subviews (Broken into Computed Properties)

    private var backgroundGradient: some View {
        RadialGradient(
            gradient: Gradient(stops: [
                .init(color: Color(hex: "00CCFF"), location: 0.0),
                .init(color: Color.white, location: 1.0)
            ]),
            center: .top,
            startRadius: 0,
            endRadius: UIScreen.main.bounds.height * 1.5
        )
        .ignoresSafeArea()
    }

    // MARK: - Header (Logo Moved)
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image("isifLogo") // Corrected filename
                .resizable().scaledToFit()
                .frame(height: 80)
                .shadow(color: .black.opacity(0.2), radius: 3, y: 2)
                .padding(.top, 60)

            // Stroked Title Text
            ZStack {
                Text("iSayItForward")
                    .font(.custom("AvenirNext-Bold", size: 32))
                    .kerning(1.5)
                    .foregroundColor(titleStrokeColor)
                    .offset(x: 1, y: 1)

                Text("iSayItForward")
                    .font(.custom("AvenirNext-Bold", size: 32))
                    .kerning(1.5)
                    .foregroundColor(titleFillColor)
            }
            .shadow(color: .black.opacity(0.1), radius: 2, y: 1)

            // ✅ TWEAK: Added kerning to match title width
            Text("The Ultimate Way to Express Yourself")
                .font(.custom("AvenirNext-Medium", size: 16))
                .kerning(1.6) // Adjust this value to match the title's width
                .foregroundColor(primaryTextColor)
                .padding(.bottom, 10)
        }
        .padding(.bottom, 25)
    }

    private var signInForm: some View {
        VStack(spacing: 15) {
            Text("Sign In")
                .font(.custom("AvenirNext-DemiBold", size: 18))
                .foregroundColor(primaryTextColor)

            TextField("Email or Phone Number", text: $email)
                .textFieldStyle(PillTextFieldStyle())
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                // ✅ TWEAK: Darkened input text
                .foregroundColor(Color.black.opacity(0.8))

            SecureField("Enter Password", text: $password)
                .textFieldStyle(PillTextFieldStyle())
                // ✅ TWEAK: Darkened input text
                .foregroundColor(Color.black.opacity(0.8))

            Button(action: signIn) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 36, weight: .light))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(buttonBackgroundColor)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.3), radius: 5, y: 3)

            Button("Forgot Password?") { /* Action */ }
                .font(.custom("AvenirNext-Regular", size: 14))
                .foregroundColor(buttonBackgroundColor.opacity(0.9))
        }
        .padding(.horizontal, 40)
    }

    private var socialLoginSection: some View {
        VStack(spacing: 10) {
            Text("Sign In With")
                .font(.custom("AvenirNext-Regular", size: 14))
                .foregroundColor(primaryTextColor.opacity(0.8))

            HStack(spacing: 24) {
                SocialLoginButton(imageName: "googleLogo", systemFallback: "g.circle.fill") {}
                SocialLoginButton(imageName: "metaLogo", systemFallback: "infinity.circle.fill") {}
                SocialLoginButton(imageName: "appleLogo", systemFallback: "apple.logo") {}
            }
        }
        .padding(.top, 10)
    }

    private var createAccountButton: some View {
        Button {
            showingSignupSheet = true
        } label: {
            Text("Create New Account")
                .font(.custom("AvenirNext-Bold", size: 18))
                .foregroundColor(primaryTextColor)
                .padding()
                .frame(maxWidth: .infinity)
                .background(goldButtonColor)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
        }
        .sheet(isPresented: $showingSignupSheet) {
            SignupView().environmentObject(authState)
        }
        .padding(.horizontal, 40)
        .padding(.top, 15)
    }

    private var footerSection: some View {
        Text("By signing up, you agree to our Terms of Service")
            .font(.custom("AvenirNext-Regular", size: 12))
            .foregroundColor(primaryTextColor.opacity(0.8))
            .padding(.top, 25)
            .padding(.bottom, 40)
    }

    // MARK: Firebase Sign In
    private func signIn() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        Auth.auth().signIn(withEmail: trimmedEmail, password: password) { _, error in
            DispatchQueue.main.async {
                if let error = error {
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
        }
    }
}

#Preview {
    WelcomeView()
        .environmentObject(AuthState())
}
