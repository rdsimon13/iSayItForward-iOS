import SwiftUI
import FirebaseAuth
import FirebaseFirestore // This was the missing line

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    // This now correctly gets the logged-in user's name and email
    @State private var userName: String = "User"
    @State private var userEmail: String = "No email found"
    
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        ZStack {
            Color.mainAppGradient.ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Profile")
                    .font(.largeTitle.weight(.bold))
                    .foregroundColor(.white)
                    .padding(.top)

                // --- CHANGE IS HERE ---
                // I've wrapped the avatar in a ZStack and added a background
                // and border to make it pop.
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.15))
                        .shadow(radius: 5)
                    
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.white.opacity(0.8))
                        .padding(15) // Give it some space from the edge
                }
                .frame(width: 130, height: 130)
                .padding(.top, 20)

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "person.fill")
                        Text(userName)
                    }
                    Divider()
                    HStack {
                        Image(systemName: "envelope.fill")
                        Text(userEmail)
                    }
                }
                .font(.headline)
                .padding()
                .background(.white.opacity(0.85))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .foregroundColor(Color.brandDarkBlue)
                .shadow(color: .black.opacity(0.1), radius: 5, y: 2)

                Spacer()

                Button("Log Out") {
                    authManager.signOut()
                }
                .buttonStyle(PrimaryActionButtonStyle())
            }
            .padding()
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("Logout Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .onAppear(perform: fetchUserData) // Fetch user data when the view appears
        }
    }
    
    // Fetch user data from Firestore
    func fetchUserData() {
        guard let uid = authManager.user?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let document = snapshot, document.exists {
                self.userName = document.data()?["name"] as? String ?? "User"
                self.userEmail = document.data()?["email"] as? String ?? "No email found"
            } else if let user = authManager.user {
                // Fallback to Firebase Auth user data
                self.userName = user.displayName ?? "User"
                self.userEmail = user.email ?? "No email found"
            }
        }
    }
}
