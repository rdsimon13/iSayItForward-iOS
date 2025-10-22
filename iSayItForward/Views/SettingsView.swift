import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @EnvironmentObject var authState: AuthState

    var body: some View {
        ZStack {
            // Background gradient to match your DashboardView
            RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(red: 0.0, green: 0.796, blue: 1.0), location: 0.0),
                    .init(color: Color.white, location: 1.0)
                ]),
                center: .top,
                startRadius: 0,
                endRadius: UIScreen.main.bounds.height * 1.0
            )
            .ignoresSafeArea()

            VStack(spacing: 25) {
                // MARK: - Title
                Text("Settings")
                    .font(.custom("Kochasan-Bold", size: 32))
                    .foregroundColor(Color(red: 0.15, green: 0.29, blue: 0.35))
                    .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                    .padding(.top, 40)

                // MARK: - Description
                Text("This section will hold your user preferences, app appearance options, and other account-related settings.")
                    .font(.custom("Kochasan-Medium", size: 16))
                    .foregroundColor(Color.black.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Spacer()

                // MARK: - Sign Out Button
                Button(action: {
                    authState.signOut()
                }) {
                    Text("Sign Out")
                        .font(.custom("Kochasan-Bold", size: 18))
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
}
