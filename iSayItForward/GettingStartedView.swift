import SwiftUI

struct GettingStartedView: View {
    @Binding var selectedTab: Int

    var body: some View {
        NavigationStack {
            ZStack {
                GradientTheme.welcomeBackground.ignoresSafeArea()
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {

                        // MARK: - Welcome Header
                        VStack(alignment: .center, spacing: 8) {
                            Image("isiFLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 90)
                                .shadow(color: .black.opacity(0.25), radius: 5, y: 3)

                            Text("Getting Started")
                                .font(.system(size: 28, weight: .heavy, design: .rounded))
                                .foregroundColor(Color.brandDarkBlue)

                            Text("Learn how to make the most of iSayItForward.")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.black.opacity(0.75))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.9))
                                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                        )
                        .padding(.horizontal)

                        // MARK: - Step Cards
                        VStack(spacing: 16) {
                            GettingStartedStep(
                                stepNumber: 1,
                                title: "Create Your First SIF",
                                description: "Start by composing a personalized message with our easy-to-use composer.",
                                iconName: "square.and.pencil"
                            )
                            GettingStartedStep(
                                stepNumber: 2,
                                title: "Add Your Signature",
                                description: "Enhance your SIFs with a digital signature for a personal touch.",
                                iconName: "signature"
                            )
                            GettingStartedStep(
                                stepNumber: 3,
                                title: "Choose Templates",
                                description: "Browse our template gallery for quick and beautiful message designs.",
                                iconName: "doc.on.doc"
                            )
                            GettingStartedStep(
                                stepNumber: 4,
                                title: "Schedule Delivery",
                                description: "Never forget important dates — schedule your SIFs for future delivery.",
                                iconName: "calendar.badge.clock"
                            )
                        }
                        .padding(.horizontal)

                        // MARK: - Quick Actions
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Quick Actions")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(Color.brandDarkBlue)

                            HStack(spacing: 14) {
                                Button {
                                    selectedTab = 1
                                } label: {
                                    QuickAction(iconName: "square.and.pencil", text: "Create SIF")
                                }

                                Button {
                                    selectedTab = 2
                                } label: {
                                    QuickAction(iconName: "doc.on.doc", text: "Templates")
                                }

                                Button {
                                    selectedTab = 3
                                } label: {
                                    QuickAction(iconName: "calendar", text: "Schedule")
                                }
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(18)
                        .shadow(color: .black.opacity(0.1), radius: 6, y: 3)
                        .padding(.horizontal)

                        // MARK: - CTA Button
                        PrimaryActionButton(
                            title: "Start Creating!",
                            gradientColors: [Color.yellow, Color.orange],
                            action: {
                                withAnimation(.spring()) {
                                    selectedTab = 1
                                }
                            }
                        )
                        .padding(.horizontal, 40)
                        .padding(.top, 10)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Getting Started")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Step Card Component
private struct GettingStartedStep: View {
    let stepNumber: Int
    let title: String
    let description: String
    let iconName: String

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.brandDarkBlue)
                    .frame(width: 42, height: 42)
                Text("\(stepNumber)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.brandDarkBlue)

                Text(description)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Image(systemName: iconName)
                .font(.system(size: 22))
                .foregroundColor(Color.brandDarkBlue.opacity(0.7))
        }
        .padding()
        .background(Color.white.opacity(0.9))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 5, y: 3)
    }
}

// MARK: - Quick Action Component
private struct QuickAction: View {
    let iconName: String
    let text: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(Color.brandDarkBlue)

            Text(text)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(Color.brandDarkBlue)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.7))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
    }
}

#Preview {
    GettingStartedView(selectedTab: .constant(0))
}
