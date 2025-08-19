import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @State private var showingSignOutAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.vibrantGradient.ignoresSafeArea()

                VStack(spacing: 30) {
                    Text("Profile")
                        .font(.largeTitle.weight(.bold))
                        .foregroundColor(.white)
                        .padding(.top, 50)

                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 100))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(Auth.auth().currentUser?.email ?? "your@email.com")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(.white.opacity(0.2))
                        .cornerRadius(10)

                    Spacer()

                    Button("Sign Out", role: .destructive) {
                        showingSignOutAlert = true
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    try? Auth.auth().signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
}
