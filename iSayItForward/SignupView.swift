// ✅ SignupView.swift
import SwiftUI

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
                Color.mainAppGradient.ignoresSafeArea()

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
        let newUser = AppUser(uid: "demoUID", name: name, email: email)
        print("✅ [Demo Mode] Signed up user: \(newUser.name)")
        onSignup?(newUser)
        presentationMode.wrappedValue.dismiss()
    }
}
