import SwiftUI

struct GettingStartedView: View {
    // This state variable will control the tab bar
    @State private var selectedTab: Tab = .home

    var body: some View {
        NavigationStack {
            ZStack {
                // MARK: - Background
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

                // Main content container
                VStack(spacing: 0) {
                    
                    // MARK: - Scroll Content
                    ScrollView {
                        VStack(spacing: 30) {
                            // App Header
                            VStack(spacing: 5) {
                                Image("isifLogo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 80)
                                    .shadow(color: .black.opacity(0.2), radius: 5, y: 3)
                                    .padding(.top, 40)

                                Text("iSayItForward")
                                    .font(.custom("Kodchasan-Bold", size: 38))
                                    .kerning(1.5)
                                    .foregroundColor(Color(hex: "132E37"))
                                    .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                            }

                            // Welcome Card
                            VStack(alignment: .center, spacing: 10) {
                                Text("Welcome Aboard!")
                                    .font(.custom("Kodchasan-Bold", size: 22))
                                    .foregroundColor(Color(hex: "132E37"))

                                Text("iSayItForward is your personal time capsule for messages. Discover a meaningful way to connect with your future self, friends, and family.")
                                    .font(.custom("Kodchasan-Regular", size: 16))
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.black.opacity(0.7))
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

                            // How It Works Section
                            VStack(alignment: .leading, spacing: 20) {
                                Text("Your First Steps")
                                    .font(.custom("Kodchasan-Bold", size: 24))
                                    .foregroundColor(Color(hex: "132E37"))
                                    .shadow(color: .white.opacity(0.5), radius: 2, y: 1)
                                    .padding(.horizontal)

                                VStack(spacing: 15) {
                                    FeatureCard(
                                        icon: "square.and.pencil",
                                        title: "Compose a SIF",
                                        description: "Write messages, add photos, or record voice notes. Make it personal!"
                                    )
                                    FeatureCard(
                                        icon: "calendar",
                                        title: "Set the Time",
                                        description: "Choose a specific date and time for your message to be revealed."
                                    )
                                    FeatureCard(
                                        icon: "paperplane.fill",
                                        title: "Send It Forward",
                                        description: "Your message is securely stored and delivered right on schedule."
                                    )
                                }
                                .padding(.horizontal)
                            }

                            // CTA Button
                            NavigationLink(destination: CreateSIFView()) {
                                Label("Start Your First SIF", systemImage: "plus.circle.fill")
                                    .font(.custom("Kodchasan-Bold", size: 18))
                                    .kerning(1.2)
                                    .foregroundColor(Color(hex: "132E37"))
                                    .padding(.vertical, 15)
                                    .padding(.horizontal, 30)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        Capsule()
                                            .fill(Color(hex: "FFB300"))
                                            .shadow(color: .black.opacity(0.3), radius: 6, y: 4)
                                    )
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.black.opacity(0.8), lineWidth: 1)
                                    )
                            }
                            .padding(.horizontal, 30)
                            .padding(.bottom, 40) // Padding for scroll bottom
                        }
                        .padding(.vertical, 20)
                    } // End ScrollView
                    
                    Spacer(minLength: 0) // Ensures content pushes to the top

                    // MARK: - Persistent Bottom Nav
                    // This is the same, stable navigation bar from your DashboardView
                    DashboardNavBar(selectedTab: $selectedTab)
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                        )
                        .padding(.horizontal)
                        .padding(.bottom, 5)
                        
                } // End Main VStack
            } // End ZStack
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Helpers
private struct CardBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 25)
            .fill(Color.white.opacity(0.8))
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
                .font(.title)
                .foregroundColor(Color(hex: "0066CC"))
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.custom("Kodchasan-SemiBold", size: 18))
                    .foregroundColor(Color(hex: "132E37"))
                Text(description)
                    .font(.custom("Kodchasan-Regular", size: 15))
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.9))
                .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
        )
    }
}

// MARK: - Bottom Nav Components
// These are defined privately here to make this file self-contained
// and avoid conflicting with your DashboardView.

private enum Tab {
    case home, compose, profile, schedule, settings
}

private struct DashboardNavBar: View {
    @Binding var selectedTab: Tab

    var body: some View {
        HStack {
            DashboardTab(icon: "house.fill", label: "Home", tab: .home, selectedTab: $selectedTab)
            DashboardTab(icon: "square.and.pencil", label: "Compose", tab: .compose, selectedTab: $selectedTab)
            DashboardTab(icon: "person.fill", label: "Profile", tab: .profile, selectedTab: $selectedTab)
            DashboardTab(icon: "calendar", label: "Schedule", tab: .schedule, selectedTab: $selectedTab)
            DashboardTab(icon: "gearshape.fill", label: "Settings", tab: .settings, selectedTab: $selectedTab)
        }
    }
}

private struct DashboardTab: View {
    let icon: String
    let label: String
    let tab: Tab
    @Binding var selectedTab: Tab
    var isActive: Bool { selectedTab == tab }

    var body: some View {
        Button { selectedTab = tab } label: {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 22))
                Text(label).font(.custom("Kodchasan-Medium", size: 10))
            }
            .foregroundColor(isActive ? Color(red: 0.651, green: 0.451, blue: 0.200) : .gray.opacity(0.8))
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    GettingStartedView()
}
