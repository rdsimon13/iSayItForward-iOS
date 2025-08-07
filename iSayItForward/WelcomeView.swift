import SwiftUI
import FirebaseAuth

struct WelcomeView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showingSignupSheet = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoggedIn = false
    @State private var currentUser: AppUser?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mainAppGradient.ignoresSafeArea()

                VStack(spacing: 20) {
                    Spacer()

                    Image("isifLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 96, height: 96)

                    Text("iSayItForward")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color.brandDarkBlue)

                    Text("Welcome to the SIF Gateway")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(Color.brandDarkBlue)
                        .multilineTextAlignment(.center)

                    Text("The Ultimate Way to Express Yourself")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Text("Sign In or Register")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.top)
                        .foregroundColor(Color.brandDarkBlue)

                    TextField("Email or Phone Number", text: $email)
                        .textFieldStyle(PillTextFieldStyle())
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)

                    SecureField("Enter Password", text: $password)
                        .textFieldStyle(PillTextFieldStyle())

                    Button("Sign In") {
                        Auth.auth().signIn(withEmail: email, password: password) { result, error in
                            if let error = error {
                                alertMessage = error.localizedDescription
                                showingAlert = true
                                return
                            }
                            if let user = result?.user {
                                currentUser = AppUser(uid: user.uid, name: user.displayName ?? "", email: email)
                                isLoggedIn = true
                            }
                        }
                    }
                    .buttonStyle(SecondaryActionButtonStyle())

                    Button("Forgot Password?") {
                        alertMessage = "Password reset is unavailable in demo mode."
                        showingAlert = true
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
                    }
                    .buttonStyle(PrimaryActionButtonStyle())

                    Text("By signing up, you agree to our Terms of Service")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)
                .sheet(isPresented: $showingSignupSheet) {
                    SignupView { user in
                        currentUser = user
                        isLoggedIn = true
                        showingSignupSheet = false
                    }
                }
                .alert(isPresented: $showingAlert) {
                    Alert(title: Text("Notice"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                }

                NavigationLink(destination: HomeView(), isActive: $isLoggedIn) {
                    EmptyView()
                }
            }
        }
    }
}
