import SwiftUI
import FirebaseAuth

struct SignupView: View {
    var onSignup: ((AppUser) -> Void)? = nil

    @Environment(\.presentationMode) var presentationMode
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            ZStack {
                self.appGradientTopOnly()

                VStack(spacing: 20) {
                    Text("Create Account")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom, 30)
                        .foregroundColor(.white)

                    TextField("Your Name", text: $name)
                        .textFieldStyle(PillTextFieldStyle())

                    TextField("Your Email", text: $email)
                        .textFieldStyle(PillTextFieldStyle())
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)

                    SecureField("Create Password", text: $password)
                        .textFieldStyle(PillTextFieldStyle())

                    Spacer()

                    Button("Sign Up") {
                        handleDemoSignup()
                    }
                    .buttonStyle(PrimaryActionButtonStyle())
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

    func handleDemoSignup() {
        guard !name.isEmpty, !email.isEmpty, !password.isEmpty else {
            alertMessage = "Please fill out all fields."
            showingAlert = true
            return
        }
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                alertMessage = error.localizedDescription
                showingAlert = true
                return
            }
            if let user = result?.user {
                let newUser = AppUser(uid: user.uid, name: name, email: email)
                onSignup?(newUser)
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}
