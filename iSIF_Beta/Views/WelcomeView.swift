import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// MARK: - Welcome View
struct WelcomeView: View {
    @EnvironmentObject var authState: AuthState
    @StateObject private var authManager = AppAuthManager()

    @State private var emailOrPhone = ""
    @State private var password = ""
    @State private var verificationCode = ""
    @State private var verificationID: String?
    @State private var showingSignupSheet = false
    @State private var isLoading = false
    @State private var bannerMessage: String?
    @State private var bannerVisible = false

    let primaryTextColor = Color.black.opacity(0.75)

    var body: some View {
        ZStack {
            NavigationStack {
                ZStack {
                    backgroundGradient
                        .allowsHitTesting(false)

                    ScrollView {
                        VStack(spacing: 22) {
                            headerSection
                            signInForm
                            socialLoginSection
                            createAccountButton
                            footerSection
                        }
                    }
                }
                .navigationBarHidden(true)
            }

            if isLoading {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                ProgressView("Please wait...")
                    .padding(24)
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(16)
                    .shadow(radius: 10)
            }

            if let message = bannerMessage, bannerVisible {
                VStack {
                    Text(message)
                        .font(.custom("AvenirNext-DemiBold", size: 16))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue.opacity(0.85))
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(2)
                    Spacer()
                }
                .padding(.top, 40)
                .animation(.spring(), value: bannerVisible)
            }
        }
        .modifier(HideKeyboardOnTapModifier())
    }

    // MARK: - Background
    private var backgroundGradient: some View {
        ZStack {
            LinearGradient(
                colors: [Color.white, Color.cyan.opacity(0.2)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            GeometryReader { geo in
                let safeHeight = max(geo.size.height, 1)
                RadialGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(hex: "00CCFF"), location: 0.0),
                        .init(color: Color.white, location: 1.0)
                    ]),
                    center: .bottom,
                    startRadius: 0,
                    endRadius: safeHeight * 0.8
                )
                .ignoresSafeArea()
            }
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 4) {
            Image("isiFLogo")
                .resizable()
                .scaledToFit()
                .frame(height: 120)
                .shadow(color: .white.opacity(0.99), radius: 6, y: 4)
                .shadow(color: .black.opacity(0.15), radius: 6, y: 4)
                .padding(.top, 60)

            ZStack {
                Text("iSayItForward")
                    .font(.custom("AvenirNext-CondensedHeavy", size: 40))
                    .kerning(4.5)
                    .foregroundColor(Color(hex: "132E37"))
                    .offset(x: 1, y: -15)
                    .shadow(color: .black.opacity(0.3), radius: 4, y: 3)

                Text("iSayItForward")
                    .font(.custom("AvenirNext-CondensedHeavy", size: 40.4))
                    .kerning(4.5)
                    .foregroundColor(Color(hex: "E6F4F5"))
                    .offset(x: 1, y: -14)
                    .shadow(color: .black.opacity(1.0), radius: 4, y: 3)
            }

            Text("The Ultimate Way to Express Yourself")
                .font(.custom("AvenirNext-CondensedLight", size: 17))
                .kerning(1.4)
                .multilineTextAlignment(.center)
                .foregroundColor(Color(hex: "2B2B2B").opacity(0.9))
                .overlay(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.cyan.opacity(0.4),
                            Color.brown.opacity(0.9)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .mask(
                        Text("The Ultimate Way to Express Yourself")
                            .font(.custom("AvenirNext-CondensedLight", size: 17))
                            .kerning(1.4)
                            .multilineTextAlignment(.center)
                    )
                )
                .shadow(color: .black.opacity(0.25), radius: 1.5, y: 1)
                .padding(.top, 2)
                .padding(.bottom, 10)
        }
        .padding(.bottom, 10)
    }

    // MARK: - Sign In Form
    private var signInForm: some View {
        VStack(spacing: 16) {
            Text("SIGN IN")
                .font(.custom("AvenirNext-CondensedMedium", size: 18))
                .kerning(3.4)
                .foregroundColor(primaryTextColor)

            CapsuleInputFieldWelcome(placeholder: "Email or Phone Number", text: $emailOrPhone)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)

            if !isPhoneNumber(emailOrPhone) {
                CapsuleInputFieldWelcome(placeholder: "Enter Password", text: $password, secure: true)
            }

            if verificationID != nil {
                CapsuleInputFieldWelcome(placeholder: "Enter Verification Code", text: $verificationCode)
            }

            Button(action: handleSignIn) {
                Image("formkit_submit")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.white)
            }
            .buttonStyle(DarkBluePillButtonStyle_Welcome()) // ✅ Fixed: Dark blue style restored
            .padding(.top, 10)
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Social Login
    private var socialLoginSection: some View {
        VStack(spacing: 10) {
            Text("Sign In With")
                .font(.custom("AvenirNext-Regular", size: 14))
                .foregroundColor(primaryTextColor.opacity(0.8))
                .kerning(2.0)

            HStack(spacing: 22) {
                SocialLoginButton(imageName: "googleLogo1", systemFallback: "g.circle.fill") {
                    showBanner("🔵 Google Sign In tapped")
                }
                SocialLoginButton(imageName: "appleLogo1", systemFallback: "applelogo") {
                    showBanner("⚫️ Apple Sign In tapped")
                }
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Create Account Button
    private var createAccountButton: some View {
        Button { showingSignupSheet = true } label: {
            Text("Create New Account!")
                .font(.custom("AvenirNext-CondensedMedium", size: 18))
                .tracking(3.2)
                .foregroundColor(.black)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(
                    Capsule().fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "FFD700"),
                                Color(hex: "E6AC00")
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                )
                .shadow(color: .black.opacity(0.25), radius: 4, y: 3)
        }
        .sheet(isPresented: $showingSignupSheet) {
            SignupView().environmentObject(authState)
        }
        .padding(.horizontal, 40)
        .padding(.top, 15)
    }

    // MARK: - Footer
    private var footerSection: some View {
        Text("By signing up, you agree to our Terms of Service")
            .font(.custom("AvenirNext-Regular", size: 12))
            .foregroundColor(primaryTextColor.opacity(0.8))
            .padding(.top, 25)
            .padding(.bottom, 40)
    }

    // MARK: - Handle Sign In
    private func handleSignIn() {
        Task {
            isLoading = true
            defer { isLoading = false }

            do {
                if isPhoneNumber(emailOrPhone) {
                    #if targetEnvironment(simulator)
                    showBanner("⚠️ Phone sign-in unavailable in Simulator.")
                    #else
                    if let verificationID = verificationID {
                        _ = try await authManager.signInWithVerificationCode(
                            verificationID: verificationID,
                            verificationCode: verificationCode
                        )
                        authState.isUserLoggedIn = true
                        showBanner("✅ Signed in with phone")
                    } else {
                        verificationID = try await authManager.sendPhoneVerification(to: emailOrPhone)
                        showBanner("📲 Verification code sent to \(emailOrPhone)")
                    }
                    #endif
                } else {
                    _ = try await authManager.signIn(email: emailOrPhone, password: password)
                    authState.isUserLoggedIn = true
                    showBanner("✅ Welcome back!")
                }
            } catch {
                showBanner("❌ \(error.localizedDescription)")
            }
        }
    }

    private func isPhoneNumber(_ input: String) -> Bool {
        let digits = input.filter(\.isNumber)
        return digits.count >= 10
    }

    private func showBanner(_ message: String) {
        withAnimation {
            bannerMessage = message
            bannerVisible = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { bannerVisible = false }
        }
    }
}

// MARK: - Capsule Input Field
struct CapsuleInputFieldWelcome: View {
    var placeholder: String
    @Binding var text: String
    var secure: Bool = false
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            Capsule()
                .fill(Color.white)
                .overlay(
                    Capsule()
                        .stroke(isFocused ? Color(hex: "00AEEF") : Color.black.opacity(0.35), lineWidth: 1.2)
                )
                .shadow(color: .white.opacity(0.6), radius: 2, y: -1)
                .shadow(color: .black.opacity(0.15), radius: 3, y: 2)

            if secure {
                SecureField(placeholder, text: $text)
                    .focused($isFocused)
                    .padding(.horizontal, 20)
                    .frame(height: 50)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .textContentType(.none)
                    .multilineTextAlignment(.center)
            } else {
                TextField(placeholder, text: $text)
                    .focused($isFocused)
                    .padding(.horizontal, 20)
                    .frame(height: 50)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: - Dark Blue Pill Button Style (for WelcomeView)
struct DarkBluePillButtonStyle_Welcome: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .bold, design: .rounded))
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                Capsule()
                    .fill(Color(hex: "2F395C"))
                    .shadow(color: .white.opacity(0.85), radius: 10, y: 0)
                    .shadow(color: .black.opacity(configuration.isPressed ? 0.15 : 0.35),
                            radius: configuration.isPressed ? 2 : 6, y: 4)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Hide Keyboard Modifier
struct HideKeyboardOnTapModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.background(TapCatcher())
    }

    private struct TapCatcher: UIViewRepresentable {
        func makeUIView(context: Context) -> UIView {
            let view = UIView()
            view.backgroundColor = .clear
            let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.dismissKeyboard))
            tap.cancelsTouchesInView = false
            view.addGestureRecognizer(tap)
            return view
        }
        func updateUIView(_ uiView: UIView, context: Context) {}
        func makeCoordinator() -> Coordinator { Coordinator() }

        class Coordinator {
            @objc func dismissKeyboard() {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
    }
}

#Preview {
    WelcomeView().environmentObject(AuthState())
}
