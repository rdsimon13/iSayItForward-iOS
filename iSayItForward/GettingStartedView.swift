import SwiftUI

struct GettingStartedView: View {
    // These would be connected to your app's state
    @EnvironmentObject var authState: AuthState
    @EnvironmentObject var matchDataState: MatchDataState

    var body: some View {
        NavigationStack {
            ZStack {
                // FIXED: Use the new vibrant gradient
                Theme.vibrantGradient.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // --- Welcome Header ---
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Getting Started")
                                .font(.largeTitle.weight(.bold))
                                .foregroundColor(.white) // FIXED: Use white text

                            Text("Learn how to make the most of iSayItForward")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.8)) // FIXED: Use white text
                        }

                        // --- Feature Explanation Cards ---
                        FeatureCard(
                            iconName: "square.and.pencil",
                            title: "Create a SIF",
                            description: "Compose heartfelt messages, attach media, and schedule them for future delivery to your loved ones."
                        )
                        
                        FeatureCard(
                            iconName: "calendar",
                            title: "Schedule with Precision",
                            description: "Never miss an important date again. Set the exact day and time for your message to be sent."
                        )
                        
                        FeatureCard(
                            iconName: "lock.shield",
                            title: "Secure & Private",
                            description: "Your messages are encrypted and stored securely, ensuring your private words remain private."
                        )

                        Spacer()
                    }
                    .padding()
                }
                .navigationTitle("Getting Started")
            }
        }
    }
}

// A helper view for displaying features on this screen
private struct FeatureCard: View {
    let iconName: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: iconName)
                .font(.largeTitle)
                .foregroundColor(.white)
                .frame(width: 50)

            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline.weight(.bold))
                Text(description)
                    .font(.subheadline)
                    .opacity(0.8)
            }
            .foregroundColor(.white)
        }
        .padding()
        .frostedGlass() // Use our frosted glass style
    }
}
