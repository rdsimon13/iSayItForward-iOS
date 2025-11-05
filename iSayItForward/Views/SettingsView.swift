import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @EnvironmentObject var authState: AuthState
    @EnvironmentObject var router: TabRouter   // ✅ Used for back + reset navigation

    var body: some View {
        ZStack {
            // MARK: - Background Gradient
            RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(red: 0.0, green: 0.796, blue: 1.0), location: 0.0),
                    .init(color: Color.white, location: 1.0)
                ]),
                center: .top,
                startRadius: 0,
                endRadius: UIScreen.main.bounds.height
            )
            .ignoresSafeArea()

            VStack(spacing: 25) {

                // MARK: - Back Button
                HStack {
                    Button(action: {
                        router.selectedTab = .home   // ✅ Return to Dashboard
                    }) {
                        Label("Back", systemImage: "chevron.left")
                            .font(.custom("AvenirNext-DemiBold", size: 16))
                            .foregroundColor(Color(red: 0.15, green: 0.29, blue: 0.35))
                            .padding(.leading, 10)
                    }
                    Spacer()
                }
                .padding(.top, 30)

                // MARK: - Title
                Text("Settings")
                    .font(.custom("AvenirNext-Bold", size: 32))
                    .foregroundColor(Color(red: 0.15, green: 0.29, blue: 0.35))
                    .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                    .padding(.top, 10)

                // MARK: - Description
                Text("Manage your preferences, account, and app options below.")
                    .font(.custom("AvenirNext-Regular", size: 16))
                    .foregroundColor(Color.black.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 20)

                // MARK: - Placeholder Options
                VStack(spacing: 16) {
                    settingsRow(icon: "person.circle.fill", title: "Account Settings")
                    settingsRow(icon: "bell.fill", title: "Notifications")
                    settingsRow(icon: "paintbrush.fill", title: "Appearance")
                    settingsRow(icon: "lock.fill", title: "Privacy & Security")
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.8))
                        .shadow(color: .black.opacity(0.1), radius: 4, y: 3)
                )

                Spacer()

                // MARK: - Sign Out Button
                Button(action: {
                    authState.signOut()             // ✅ Normal sign-out
                    router.selectedTab = .home      // ✅ Reset navigation manually
                }) {
                    Text("Sign Out")
                        .font(.custom("AvenirNext-DemiBold", size: 18))
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.85, green: 0.25, blue: 0.25),
                                    Color(red: 0.65, green: 0.05, blue: 0.05)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(15)
                        .shadow(color: .black.opacity(0.25), radius: 5, y: 3)
                }
                .padding(.horizontal, 50)
                .padding(.bottom, 50)
            }
            .padding()
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Reusable Row
    private func settingsRow(icon: String, title: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            Text(title)
                .font(.custom("AvenirNext-Regular", size: 16))
                .foregroundColor(.black.opacity(0.8))
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray.opacity(0.5))
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthState())
        .environmentObject(TabRouter())
}
