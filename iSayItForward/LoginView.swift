import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoggedIn = false

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

                        Button("Login") {
                            // Login action here
                            self.isLoggedIn = true
                        }
                        .buttonStyle(SecondaryActionButtonStyle())
                        .padding(.top)

                        NavigationLink("Don't have an account? Sign up") {
                            Text("Signup Screen")
                        }
                        .font(.footnote)
                        .padding(.top)
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
