import SwiftUI

struct WelcomeView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showingSignupSheet = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoggedIn = false
    @State private var currentUser: AppUser?
    @State private var isImageLoaded = true

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mainAppGradient.ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer()

                    // Logo with error handling
                    Group {
                        if isImageLoaded {
                            Image("isifLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 96, height: 96)
                                .onAppear {
                                    print("🖼️ iSIF Logo loaded successfully")
                                }
                        } else {
                            // Fallback icon if logo fails to load
                            Image(systemName: "bubble.left.and.bubble.right")
                                .font(.system(size: 60, weight: .light))
                                .foregroundColor(Color.brandDarkBlue.opacity(0.7))
                                .frame(width: 96, height: 96)
                                .onAppear {
                                    print("⚠️ Using fallback logo - main logo not found")
                                }
                        }
                    }

                    VStack(spacing: 8) {
                        Text("iSayItForward")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(Color.brandDarkBlue)

                        Text("The Ultimate Way to Express Yourself")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.bottom, 8)

                    Text("Sign In or Register")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.brandDarkBlue)

                    VStack(spacing: 16) {
                        TextField("Email or Phone Number", text: $email)
                            .textFieldStyle(PillTextFieldStyle())
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)

                        SecureField("Enter Password", text: $password)
                            .textFieldStyle(PillTextFieldStyle())
                    }
                    .padding(.top, 8)

                    Button("Sign In") {
                        print("🔐 User attempting sign in with email: \(email)")
                        currentUser = AppUser(uid: "demoUID", name: "Damon Sims", email: email)
                        isLoggedIn = true
                    }
                    .buttonStyle(SecondaryActionButtonStyle())
                    .padding(.top, 8)

                    Button("Forgot Password?") {
                        print("📧 Forgot password requested")
                        alertMessage = "Password reset is unavailable in demo mode."
                        showingAlert = true
                    }
                    .font(.footnote)
                    .foregroundColor(.gray)

                    Spacer()

                    VStack(spacing: 16) {
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
                            print("✍️ Create new account requested")
                            showingSignupSheet = true
                        }
                        .buttonStyle(PrimaryActionButtonStyle())

                        Text("By signing up, you agree to our Terms of Service")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }
                }
                .padding(.horizontal, 32)
                .sheet(isPresented: $showingSignupSheet) {
                    SignupView { user in
                        print("📝 New user registered: \(user.name), \(user.email)")
                        currentUser = user
                        isLoggedIn = true
                        showingSignupSheet = false
                    }
                }
                .alert(isPresented: $showingAlert) {
                    Alert(title: Text("Notice"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                }
                .navigationDestination(isPresented: $isLoggedIn) {
                    HomeView()
                }
                .onAppear {
                    print("🚀 WelcomeView appeared - checking for logo asset")
                    // Check if logo image exists
                    if UIImage(named: "isifLogo") == nil {
                        print("⚠️ Logo image 'isifLogo' not found in assets")
                        isImageLoaded = false
                    } else {
                        print("✅ Logo image found successfully")
                        isImageLoaded = true
                    }
                }
            }
        }
    }
}
