import SwiftUI

struct GettingStartedView: View {
    @EnvironmentObject var router: TabRouter
    @EnvironmentObject var authState: AuthState

    var body: some View {
        NavigationStack {
            ZStack {
                // MARK: Background
                RadialGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(red: 0.0, green: 0.796, blue: 1.0), location: 0.0),
                        .init(color: .white, location: 1.0)
                    ]),
                    center: .top,
                    startRadius: 0,
                    endRadius: UIScreen.main.bounds.height
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 30) {
                            // Header
                            VStack(spacing: 5) {
                                Image("isiFLogo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 80)
                                    .shadow(color: .black.opacity(0.2), radius: 5, y: 3)
                                    .padding(.top, 40)

                                Text("iSayItForward")
                                    .font(.custom("AvenirNext-Bold", size: 36))
                                    .kerning(1.5)
                                    .foregroundColor(Color(hex: "132E37"))
                                    .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                            }

                            // Welcome Card
                            VStack(spacing: 10) {
                                Text("Welcome Aboard!")
                                    .font(.custom("AvenirNext-DemiBold", size: 22))
                                    .foregroundColor(Color(hex: "132E37"))

                                Text("iSayItForward is your personal time capsule for meaningful connections with your future self, friends, and family.")
                                    .font(.custom("AvenirNext-Regular", size: 15))
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.black.opacity(0.75))
                            }
                            .padding(20)
                            .frame(maxWidth: .infinity)
                            .background(CardBackground())
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color.cyan.opacity(0.7), lineWidth: 1.2)
                            )
                            .padding(.horizontal)

                            Divider()
                                .frame(height: 2)
                                .background(Color.cyan.opacity(0.7))
                                .padding(.horizontal, 40)

                            // First Steps
                            VStack(alignment: .leading, spacing: 20) {
                                Text("Your First Steps")
                                    .font(.custom("AvenirNext-DemiBold", size: 22))
                                    .foregroundColor(Color(hex: "132E37"))
                                    .padding(.horizontal)

                                VStack(spacing: 15) {
                                    FeatureCard(icon: "square.and.pencil", title: "Compose a SIF", description: "Write messages, add photos, or record voice notes. Make it personal!")
                                    FeatureCard(icon: "calendar", title: "Set the Time", description: "Choose a specific date and time for your message to be revealed.")
                                    FeatureCard(icon: "paperplane.fill", title: "Send It Forward", description: "Your message is securely stored and delivered right on schedule.")
                                }
                                .padding(.horizontal)
                            }

                            // CTA Button
                            Button {
                                router.selectedTab = .compose
                            } label: {
                                Label("Start Your First SIF", systemImage: "plus.circle.fill")
                                    .font(.custom("AvenirNext-DemiBold", size: 17))
                                    .foregroundColor(.black)
                                    .padding(.vertical, 14)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        Capsule()
                                            .fill(Color(hex: "FFD700"))
                                            .shadow(color: .black.opacity(0.3), radius: 6, y: 4)
                                    )
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.black.opacity(0.8), lineWidth: 0.8)
                                    )
                            }
                            .padding(.horizontal, 30)
                            .padding(.bottom, 40)
                        }
                        .padding(.vertical, 20)
                    }

                    // Bottom Nav
                    BottomNavBar(
                        selectedTab: $router.selectedTab,
                        isVisible: .constant(true)
                    )
                    .environmentObject(router)
                    .environmentObject(authState)
                    .padding(.bottom, 5)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Supporting Views
private struct CardBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 25)
            .fill(Color.white.opacity(0.85))
            .shadow(color: .black.opacity(0.1), radius: 8, y: 5)
    }
}

private struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Color(hex: "0066CC"))
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.custom("AvenirNext-DemiBold", size: 16))
                    .foregroundColor(Color(hex: "132E37"))
                Text(description)
                    .font(.custom("AvenirNext-Regular", size: 14))
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.95))
                .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
        )
    }
}

#Preview {
    GettingStartedView()
        .environmentObject(TabRouter())
        .environmentObject(AuthState())
}
