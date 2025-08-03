import SwiftUI

struct WelcomeView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showingSignupSheet = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoggedIn = false
    @State private var currentUser: AppUser?

    var body: some View {
        ErrorBoundary {
            NavigationStack {
                ZStack {
                    // Add error handling for gradient
                    Group {
                        Color.mainAppGradient
                    }
                    .onAppear {
                        print("🎨 WelcomeView: Gradient background loaded")
                    }
                    .ignoresSafeArea()

                    VStack(spacing: 24) {
                        Spacer()

                        // Use SafeImageView for better error handling
                        SafeImageView("isifLogo", width: 96, height: 96, fallbackIcon: "app.fill")
                            .onAppear {
                                print("🖼️ WelcomeView: Logo loaded")
                            }

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
                        .padding(.top, 8)
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
                        print("🔐 WelcomeView: Sign in button tapped")
                        currentUser = AppUser(uid: "demoUID", name: "Damon Sims", email: email)
                        isLoggedIn = true
                    }
                    .buttonStyle(SecondaryActionButtonStyle())
                    .padding(.top, 8)

                    Button("Forgot Password?") {
                        alertMessage = "Password reset is unavailable in demo mode."
                        showingAlert = true
                    }
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding(.top, 4)

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
                            print("📝 WelcomeView: Create account button tapped")
                            showingSignupSheet = true
                        }
                        .buttonStyle(PrimaryActionButtonStyle())

                        Text("By signing up, you agree to our Terms of Service")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 32)
                .onAppear {
                    print("🚀 WelcomeView: View appeared")
                }
                .sheet(isPresented: $showingSignupSheet) {
                    SignupView { user in
                        print("✅ WelcomeView: User signed up: \(user.name)")
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
                        .navigationBarBackButtonHidden(true)
                }
                }
            }
        }
    }
}

#Preview {
    WelcomeView()
}
