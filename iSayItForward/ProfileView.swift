import SwiftUI
import FirebaseAuth
import FirebaseFirestore // This was the missing line

struct ProfileView: View {
    // This now correctly gets the logged-in user's name and email
    @State private var userName: String = "User"
    @State private var userEmail: String = "No email found"
    @StateObject private var settingsManager = SIFSettingsManager()
    
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color.mainAppGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack {
                            Text("Profile")
                                .font(.largeTitle.weight(.bold))
                                .foregroundColor(.white)
                                .padding(.top)
                        }

                        // User Profile Section
                        VStack(spacing: 16) {
                            // Avatar
                            ZStack {
                                Circle()
                                    .fill(.white.opacity(0.15))
                                    .shadow(radius: 5)
                                
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(.white.opacity(0.8))
                                    .padding(15)
                            }
                            .frame(width: 130, height: 130)

                            // User Info Card
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
                        }

                        // Quick Stats Overview
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            QuickStatCard(
                                title: "SIFs Sent",
                                value: "\(settingsManager.statistics.totalSIFsSent)",
                                iconName: "paperplane.fill",
                                color: Color.brandYellow
                            )
                            
                            QuickStatCard(
                                title: "Current Streak",
                                value: "\(settingsManager.statistics.currentStreak)",
                                iconName: "flame.fill",
                                color: .orange
                            )
                        }

                        // Profile Actions Section
                        VStack(spacing: 16) {
                            NavigationLink(destination: SIFPreferencesView(settingsManager: settingsManager)) {
                                ProfileActionRow(
                                    title: "SIF Preferences",
                                    description: "Manage your default settings and preferences",
                                    iconName: "gearshape.fill"
                                )
                            }
                            
                            NavigationLink(destination: SIFStatisticsView(settingsManager: settingsManager)) {
                                ProfileActionRow(
                                    title: "Statistics & History",
                                    description: "View your SIF activity and impact metrics",
                                    iconName: "chart.bar.fill"
                                )
                            }
                        }

                        Spacer(minLength: 40)

                        // Logout Button
                        Button("Log Out") {
                            do {
                                try Auth.auth().signOut()
                            } catch let signOutError as NSError {
                                self.alertMessage = "Error signing out: \(signOutError.localizedDescription)"
                                self.showingAlert = true
                            }
                        }
                        .buttonStyle(PrimaryActionButtonStyle())
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("Logout Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .onAppear(perform: fetchUserData)
        }
    }
    
    // Fetch user data from Firestore
    func fetchUserData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let document = snapshot, document.exists {
                self.userName = document.data()?["name"] as? String ?? "User"
                self.userEmail = document.data()?["email"] as? String ?? "No email found"
            }
        }
    }
}

// MARK: - Supporting Views
private struct QuickStatCard: View {
    let title: String
    let value: String
    let iconName: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundColor(Color.brandDarkBlue)
            
            Text(title)
                .font(.caption)
                .foregroundColor(Color.brandDarkBlue.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.white.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 3, y: 1)
    }
}

private struct ProfileActionRow: View {
    let title: String
    let description: String
    let iconName: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(Color.brandDarkBlue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundColor(Color.brandDarkBlue)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(Color.brandDarkBlue.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.medium))
                .foregroundColor(Color.brandDarkBlue.opacity(0.5))
        }
        .padding()
        .background(.white.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
    }
}
