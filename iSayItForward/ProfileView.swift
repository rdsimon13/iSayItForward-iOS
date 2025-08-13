import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ProfileView: View {
    // MARK: - User Info
    @State private var userName: String = "User"
    @State private var userEmail: String = "No email found"

    // MARK: - Alerts
    @State private var showingAlert = false
    @State private var alertMessage = ""

    // MARK: - Signatures
    @State private var showingSignatureView = false
    @State private var savedSignatures: [SignatureData] = []   // Uses your existing type

    var body: some View {
        ZStack {
            // Official profile variant — top only so the tab bar remains opaque white
            Color.profileGradient.ignoresSafeArea(edges: .top)

            ScrollView {
                VStack(spacing: 20) {
                    header
                    userCard
                    signatureManagement
                    logoutButton
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
        }
        .sheet(isPresented: $showingSignatureView) {
            SignatureView(isPresented: $showingSignatureView) { signature in
                savedSignatures.append(signature)
            }
        }
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Logout Error"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear(perform: fetchUserData)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Sections

    private var header: some View {
        VStack(spacing: 20) {
            Text("Profile")
                .font(.largeTitle.weight(.bold))
                .foregroundColor(.white)
                .padding(.top)

            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .shadow(radius: 5)

                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.white.opacity(0.85))
                    .padding(15)
            }
            .frame(width: 138, height: 138)
        }
        .padding(.top, 12)
    }

    private var userCard: some View {
        VStack(spacing: 8) {
            Text(userName)
                .font(.title2.weight(.semibold))
                .foregroundColor(.white)

            Text(userEmail)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.85))
        }
    }

    private var signatureManagement: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Signature Management")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Spacer()

                Button("Add Signature") {
                    showingSignatureView = true
                }
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            if savedSignatures.isEmpty {
                Text("No signatures saved yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ForEach(savedSignatures.prefix(2)) { signature in
                    SignaturePreviewView(signatureData: signature)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.1), radius: 5, y: 2)
    }

    private var logoutButton: some View {
        Button {
            do {
                try Auth.auth().signOut()
                // AuthState will flip and root will show WelcomeView automatically.
            } catch {
                alertMessage = "Error signing out: \(error.localizedDescription)"
                showingAlert = true
            }
        } label: {
            Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.12))
                .foregroundColor(.red)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .padding(.top, 8)
    }

    // MARK: - Data

    private func fetchUserData() {
        if let user = Auth.auth().currentUser {
            userEmail = user.email ?? userEmail
            userName  = user.displayName ?? userName
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .previewDisplayName("Profile")
    }
}
