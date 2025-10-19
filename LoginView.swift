import SwiftUI
import Firebase

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoggedIn = false
    @State private var errorMessage: String? = nil
    @EnvironmentObject var authState: AuthState

    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                ZStack {
                    self.appGradientTopOnly()

                    VStack(spacing: 20) {
                        Text("iSayItForward")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Login to Your Account")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        TextField("Email or Phone Number", text: $email)
                            .textFieldStyle(PillTextFieldStyle())
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)

                        SecureField("Enter Password", text: $password)
                            .textFieldStyle(PillTextFieldStyle())
                        
                        // Show error message if any
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding(.top, 4)
                        }

                        Button("Login") {
                            // Connect to Firebase Auth
                            if !email.isEmpty && !password.isEmpty {
                                authState.signIn(email: email, password: password) { success, error in
                                    if success {
                                        self.isLoggedIn = true
                                        self.errorMessage = nil
                                    } else {
                                        self.errorMessage = error ?? "Login failed"
                                        print("Login failed: \(error ?? "Unknown error")")
                                    }
                                }
                            } else {
                                self.errorMessage = "Please enter email and password"
                            }
                        }
                        .buttonStyle(SecondaryActionButtonStyle())
                        .padding(.top)

                        NavigationLink("Don't have an account? Sign up") {
                            Text("Signup Screen")
                        }
                        .font(.footnote)
                        .padding(.top)
                        
                        // Development shortcut
                        #if DEBUG
                        Button("Skip Login (Dev)") {
                            authState.simulateLogin()
                            self.isLoggedIn = true
                        }
                        .font(.caption)
                        .padding(.top)
                        #endif
                    }
                    .padding(.horizontal, 32)
                    .navigationDestination(isPresented: $isLoggedIn) {
                        HomeView()
                    }
                }
            }
        } else {
            Text("iSayItForward requires iOS 16.0 or newer.")
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
                .padding()
        }
    }
}
