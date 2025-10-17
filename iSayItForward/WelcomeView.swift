import SwiftUI
import FirebaseAuth

struct WelcomeView: View {
    @EnvironmentObject var authState: AuthState
    @State private var displayName: String = ""

    var body: some View {
        ZStack {
            GradientTheme.welcomeBackground
                .ignoresSafeArea()

            VStack(spacing: 20) {

                // MARK: - Header
                VStack(spacing: 8) {
                    Image("isiFLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 110)
                        .shadow(color: .black.opacity(0.3), radius: 6, y: 3)

                    Text("iSayItForward")
                        .font(TextStyles.title(34))
                        .foregroundColor(Color.black.opacity(0.85))

                    Text("The Ultimate Way to Express Yourself")
                        .font(TextStyles.subtitle(16))
                        .foregroundColor(Color.black.opacity(0.6))
                        .padding(.bottom, 10)
                }
                .padding(.top, 25)

                // MARK: - Welcome Card
                VStack(spacing: 6) {
                    Text("Welcome to iSIF, \(displayName.isEmpty ? "Friend" : displayName).")
                        .font(TextStyles.subtitle(18))
                        .foregroundColor(Color.black.opacity(0.85))

                    Text("Choose an option below to get started.")
                        .font(TextStyles.body(15))
                        .foregroundColor(Color.black.opacity(0.65))
                }
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.white.opacity(0.96))
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color.black.opacity(0.15), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
                )
                .padding(.horizontal, 28)

                // MARK: - Feature Buttons
                VStack(spacing: 18) {
                    HStack(spacing: 36) {

                        // GETTING STARTED
                        VStack(spacing: 6) {
                            Image("Large FAB")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 64, height: 70)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(red: 0.35, green: 0.24, blue: 0.1), lineWidth: 2)
                                )
                                .shadow(color: Color(red: 0.35, green: 0.24, blue: 0.1).opacity(0.3), radius: 3, y: 2)
                                .shadow(color: .white.opacity(0.4), radius: 2)
                                .blur(radius: 0.1)

                            Text("Getting\nStarted")
                                .font(.custom("AvenirNext-Italic", size: 13))
                                .multilineTextAlignment(.center)
                                .foregroundColor(Color.black.opacity(0.75))
                                .frame(maxWidth: 70)
                        }

                        // CREATE A SIF
                        VStack(spacing: 6) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(Color(red: 0.94, green: 0.92, blue: 0.95))
                                    .frame(width: 86, height: 86)
                                    .shadow(color: Color(red: 0.55, green: 0.55, blue: 0.75).opacity(0.4), radius: 6, y: 3)

                                Image("Large FAB-1")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 45, height: 45)
                            }

                            Text("CREATE\nA SIF")
                                .font(.custom("AvenirNext-DemiBold", size: 13))
                                .multilineTextAlignment(.center)
                                .foregroundColor(Color.black.opacity(0.75))
                        }

                        // MANAGE MY SIFs
                        VStack(spacing: 6) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(Color(red: 0.94, green: 0.92, blue: 0.95))
                                    .frame(width: 86, height: 86)
                                    .shadow(color: Color(red: 0.55, green: 0.55, blue: 0.75).opacity(0.4), radius: 6, y: 3)

                                Image("Large FAB-2")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 45, height: 45)
                            }

                            Text("MANAGE\nMY SIFs")
                                .font(.custom("AvenirNext-DemiBold", size: 13))
                                .multilineTextAlignment(.center)
                                .foregroundColor(Color.black.opacity(0.75))
                        }
                    }

                    Rectangle()
                        .fill(Color.black.opacity(0.25))
                        .frame(height: 2)
                        .cornerRadius(2)
                        .padding(.horizontal, 50)
                        .padding(.top, 14)
                }

                // MARK: - SIF Template Gallery
                ZStack {
                    VStack(spacing: 12) {
                        Button {
                            print("🖼️ Gallery tapped")
                        } label: {
                            Text("SIF Template Gallery")
                                .font(TextStyles.subtitle(17))
                                .foregroundColor(.white)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(
                                    Capsule()
                                        .fill(GradientTheme.deepBlue)
                                        .shadow(color: .black.opacity(0.4), radius: 5, y: 3)
                                )
                        }
                        .padding(.horizontal, 70)

                        Text("Explore a variety of ready-made templates designed to help you express yourself with style and speed.")
                            .font(TextStyles.body(14))
                            .foregroundColor(Color.black.opacity(0.75))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }

                    HStack {
                        Spacer()
                        Image("4 2")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .rotationEffect(.degrees(8))
                            .offset(x: 35, y: 5)
                            .shadow(color: .black.opacity(0.25), radius: 3, y: 2)
                    }
                    .padding(.trailing, 45)
                }
                .padding(.top, 4)

                // MARK: - Schedule Section
                ZStack {
                    VStack(spacing: 12) {
                        Button {
                            print("📅 Schedule tapped")
                        } label: {
                            Text("Schedule a SIF")
                                .font(TextStyles.subtitle(17))
                                .foregroundColor(.white)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(
                                    Capsule()
                                        .fill(GradientTheme.deepBlue)
                                        .shadow(color: .black.opacity(0.4), radius: 5, y: 3)
                                )
                        }
                        .padding(.horizontal, 70)

                        Text("Never forget to send greetings on that special day again. Schedule your SIF for future delivery today!")
                            .font(TextStyles.body(14))
                            .foregroundColor(Color.black.opacity(0.75))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }

                    HStack {
                        Image("5 2")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .rotationEffect(.degrees(-8))
                            .offset(x: -35, y: 5)
                            .shadow(color: .black.opacity(0.25), radius: 3, y: 2)
                        Spacer()
                    }
                    .padding(.leading, 45)
                }
                .padding(.top, 6)

                Spacer(minLength: 10)

                // MARK: - Bottom Navigation
                WelcomeNavBar()
                    .padding(.bottom, 8)
            }
            .onAppear {
                if let user = Auth.auth().currentUser {
                    displayName = user.displayName ?? user.email?.components(separatedBy: "@").first?.capitalized ?? ""
                }
            }
        }
    }
}

// MARK: - Bottom Navigation Bar
struct WelcomeNavBar: View {
    var body: some View {
        HStack(spacing: 38) {
            WelcomeTab(icon: "house.fill", label: "Home")
            WelcomeTab(icon: "square.and.pencil", label: "Compose")
            WelcomeTab(icon: "person.crop.circle", label: "Profile")
            WelcomeTab(icon: "calendar", label: "Schedule")
            WelcomeTab(icon: "gearshape", label: "Settings")
        }
    }
}

// MARK: - Tab Component
struct WelcomeTab: View {
    let icon: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Color.black.opacity(0.85))
            Text(label)
                .font(TextStyles.small(11))
                .foregroundColor(Color.black.opacity(0.75))
        }
    }
}

#Preview {
    WelcomeView()
        .environmentObject(AuthState())
}
