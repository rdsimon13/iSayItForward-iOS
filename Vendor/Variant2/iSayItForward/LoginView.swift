import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoggedIn = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.vibrantGradient.ignoresSafeArea() // Use our new gradient

                ScrollView {
                    VStack(spacing: 24) {
                        Image("isifLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 50)
                            .padding(.top, 50)

                        Text("Login to Your Account")
                            .font(.title.weight(.bold))
                            .foregroundColor(.white)

                        // --- Form Fields with Frosted Glass Style ---
                        VStack(spacing: 16) {
                            TextField("Email Address", text: $email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                            
                            Divider().background(Color.white.opacity(0.5))
                            
                            SecureField("Password", text: $password)
                                .textContentType(.password)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(.white.opacity(0.2))
                        .cornerRadius(12)
                        
                        Button("Login") {
                            self.isLoggedIn = true
                        }
                        .foregroundColor(Theme.textDark)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.white)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 32)
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $isLoggedIn) {
                HomeView()
            }
        }
    }
}
