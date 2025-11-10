import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// MARK: - Signup View
struct SignupView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authState: AuthState
    @StateObject private var authManager = AppAuthManager()

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var emailOrPhone = ""
    @State private var phoneNumber = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var verificationCode = ""
    @State private var verificationID: String?

    @State private var isLoading = false
    @State private var showBanner = false
    @State private var bannerMessage = ""
    @State private var bannerColor = Color.clear

    var body: some View {
        ZStack {
            backgroundLayer
                .allowsHitTesting(false)

            ScrollView {
                VStack(spacing: 20) {
                    Spacer(minLength: 40)
                    headerSection
                    formSection
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
            }
            .contentShape(Rectangle())
            .hideKeyboardOnTap()

            if isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .transition(.opacity)
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.3)
            }

            if showBanner {
                VStack {
                    Text(bannerMessage)
                        .font(.custom("AvenirNext-Medium", size: 15))
                        .foregroundColor(.black)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [bannerColor.opacity(0.95), bannerColor]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(8)
                        .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
                        .padding(.horizontal, 30)
                        .padding(.top, 50)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(2)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showBanner)
    }

    // MARK: - Background Layer
    private var backgroundLayer: some View {
        VStack(spacing: 0) {
            TopWaveShape()
                .fill(Color(hex: "00CFFF"))
                .frame(height: UIScreen.main.bounds.height * 0.60)
                .overlay(
                    TopWaveShape()
                        .stroke(Color.black.opacity(0.25), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.45), radius: 6, y: 3)

            LinearGradient(
                gradient: Gradient(colors: [Color.white, Color(hex: "00B4E6").opacity(0.9)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
        .ignoresSafeArea()
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 4) {
            Image("isiFLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 165, height: 165)
                .rotationEffect(.degrees(-25))
                .offset(x: 40, y: -20)
                .shadow(color: .white.opacity(0.99), radius: 6, y: 4)
                .shadow(color: .black.opacity(0.15), radius: 6, y: 4)

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
                            Color.cyan.opacity(0.9),
                            Color.brown.opacity(0.4)
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

    // MARK: - Form Section
    private var formSection: some View {
        VStack(spacing: 16) {
            Text("Create Your Free Account")
                .font(.custom("AvenirNext-DemiBold", size: 20))
                .foregroundColor(Color.black.opacity(0.8))
                .tracking(1.2)

            HStack(spacing: 10) {
                CapsuleInputFieldSignup(placeholder: "First Name", text: $firstName)
                CapsuleInputFieldSignup(placeholder: "Last Name", text: $lastName)
            }

            CapsuleInputFieldSignup(placeholder: "Email Address", text: $emailOrPhone)
                .keyboardType(.emailAddress)
            CapsuleInputFieldSignup(placeholder: "Phone Number (optional)", text: $phoneNumber)
                .keyboardType(.phonePad)
            CapsuleInputFieldSignup(placeholder: "Create Password", text: $password, secure: true)
            CapsuleInputFieldSignup(placeholder: "Confirm Password", text: $confirmPassword, secure: true)

            Button(action: handleSignup) {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    Image("formkit_submit")
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .padding(.horizontal, 8)
                }
            }
            .buttonStyle(GoldPillButtonStylePolished())
            .padding(.top, 10)

            socialLoginSection
            termsSection
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 25)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(Color(hex: "2F395C").opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(Color.black.opacity(0.25), lineWidth: 1)
                )
                .shadow(color: .white.opacity(0.6), radius: 8, y: -2)
                .shadow(color: .black.opacity(0.25), radius: 8, y: 3)
        )
    }

    // MARK: - Social Login
    private var socialLoginSection: some View {
        VStack(spacing: 10) {
            Text("Or Sign Up With")
                .font(.custom("AvenirNext-Regular", size: 14))
                .foregroundColor(.black.opacity(0.6))
                .tracking(1.1)

            HStack(spacing: 22) {
                SocialLoginButton(imageName: "googleLogo1", systemFallback: "g.circle.fill") {}
                SocialLoginButton(imageName: "appleLogo1", systemFallback: "applelogo") {}
            }
        }
        .padding(.top, 10)
    }

    private var termsSection: some View {
        Text("By signing up, you agree to our Terms of Service")
            .font(.custom("AvenirNext-Regular", size: 12))
            .foregroundColor(.black.opacity(0.6))
            .multilineTextAlignment(.center)
            .padding(.top, 12)
    }

    // MARK: - Signup Logic
    private func handleSignup() {
        Task {
            isLoading = true
            defer { isLoading = false }

            do {
                guard !firstName.isEmpty, !lastName.isEmpty, !emailOrPhone.isEmpty else {
                    showBanner(with: "Please fill in all required fields.", color: .red)
                    return
                }

                guard password == confirmPassword else {
                    showBanner(with: "Passwords do not match.", color: .red)
                    return
                }

                if !phoneNumber.isEmpty {
                    let digits = phoneNumber.filter(\.isNumber)
                    guard digits.count >= 10 else {
                        showBanner(with: "Invalid phone number.", color: .red)
                        return
                    }
                }

                let result = try await authManager.register(email: emailOrPhone, password: password)
                let uid = result.user.uid

                let userData: [String: Any] = [
                    "firstName": firstName,
                    "lastName": lastName,
                    "email": emailOrPhone,
                    "phoneNumber": phoneNumber,
                    "createdAt": Timestamp(),
                    "updatedAt": Timestamp()
                ]

                try await authManager.saveUserProfile(uid: uid, data: userData)
                authState.isUserLoggedIn = true
                showBanner(with: "Account created successfully.", color: Color(hex: "FFD700"))
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                    dismiss()
                }

            } catch {
                showBanner(with: "Sign-up failed. Please try again.", color: .red)
                print("❌ Sign-up error: \(error.localizedDescription)")
            }
        }
    }

    private func showBanner(with message: String, color: Color) {
        bannerMessage = message
        bannerColor = color
        withAnimation {
            showBanner = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation {
                showBanner = false
            }
        }
    }
}

// MARK: - Capsule Input Field
struct CapsuleInputFieldSignup: View {
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
                        .stroke(isFocused ? Color(hex: "00AEEF") : Color.black.opacity(0.35), lineWidth: 1.1)
                )
                .shadow(color: .white.opacity(0.6), radius: 2, y: -1)
                .shadow(color: .black.opacity(0.15), radius: 3, y: 2)

            if secure {
                SecureField("", text: $text)
                    .focused($isFocused)
                    .padding(.horizontal, 20)
                    .frame(height: 46)
                    .foregroundColor(.black.opacity(0.9))
                    .font(.custom("AvenirNext-Regular", size: 16))
                    .multilineTextAlignment(.center)
                    .textContentType(.newPassword) // 🩵 prevents iOS from offering strong passwords
                    .disableAutocorrection(true)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.asciiCapable)
                    .placeholderSignup(when: text.isEmpty) {
                        Text(placeholder)
                            .font(.custom("AvenirNext-Regular", size: 16))
                            .foregroundColor(.gray.opacity(0.7))
                    }
            
            } else {
                TextField("", text: $text)
                    .focused($isFocused)
                    .padding(.horizontal, 20)
                    .frame(height: 46)
                    .foregroundColor(.black.opacity(0.9))
                    .font(.custom("AvenirNext-Regular", size: 16))
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .textContentType(
                        placeholder.localizedCaseInsensitiveContains("phone")
                        ? .telephoneNumber
                        : placeholder.localizedCaseInsensitiveContains("email")
                            ? .emailAddress
                            : .none
                    )
                    .keyboardType(
                        placeholder.localizedCaseInsensitiveContains("phone")
                        ? .phonePad
                        : placeholder.localizedCaseInsensitiveContains("email")
                            ? .emailAddress
                            : .default
                    )
                    .placeholderSignup(when: text.isEmpty) {
                        Text(placeholder)
                            .font(.custom("AvenirNext-Regular", size: 16))
                            .foregroundColor(.gray.opacity(0.7))
                    }
            }
        }
    }
}

// MARK: - Top Wave Shape
private struct TopWaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: 0, y: rect.height * 0.4))
        path.addQuadCurve(
            to: CGPoint(x: rect.width, y: rect.height * 0.3),
            control: CGPoint(x: rect.width * 0.5, y: rect.height * 0.1)
        )
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        path.closeSubpath()
        return path
    }
}

// MARK: - Gold Pill Button Style
struct GoldPillButtonStylePolished: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.custom("AvenirNext-Thin", size: 18))
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
            .shadow(color: .black.opacity(configuration.isPressed ? 0.2 : 0.4),
                    radius: configuration.isPressed ? 2 : 6, y: 4)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Placeholder Extension
extension View {
    func placeholderSignup<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .center,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            if shouldShow { placeholder() }
            self
        }
    }
}

#Preview {
    SignupView()
        .environmentObject(AuthState())
        .onAppear {
            print("⚙️ Preview mode active — Firebase calls disabled")
        }
}

