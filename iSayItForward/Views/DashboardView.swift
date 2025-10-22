import SwiftUI
import FirebaseAuth

struct DashboardView: View {
    @State private var displayName: String = ""
    @State private var selectedTab: Tab = .home

    // Figma colors for text styling
    let titleFillColor = Color(hex: "E6F4F5")
    let titleStrokeColor = Color(hex: "132E37")

    var body: some View {
        NavigationStack {
            ZStack {
                // MARK: - Background Gradient
                RadialGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(red: 0.0, green: 0.796, blue: 1.0), location: 0.0), // #00CCFF
                        .init(color: Color.white, location: 1.0)
                    ]),
                    center: .top,
                    startRadius: 0,
                    endRadius: UIScreen.main.bounds.height * 1.0
                )
                .ignoresSafeArea()

                // Main layout container
                VStack(spacing: 0) {
                    // This switch statement is the key to making the tab bar work.
                    // It changes the content based on the `selectedTab`.
                    switch selectedTab {
                    case .home:
                        homeContent
                    case .settings:
                        SettingsView()
                    default:
                        // Placeholder for other tabs like Compose, Profile, etc.
                        Spacer()
                        Text("\(String(describing: selectedTab).capitalized) View")
                            .font(.largeTitle)
                        Spacer()
                    }

                    // MARK: - Bottom Nav (Placed correctly at the bottom)
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
                }
                .onAppear(perform: loadUser)
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Home Content Subview
    private var homeContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                welcomeCard
                featureButtons
                divider
                templateGalleryCard
                scheduleCard
                Spacer(minLength: 10)
            }
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image("isifLogo").resizable().scaledToFit().frame(height: 100)
                .shadow(color: .black.opacity(0.25), radius: 5, y: 3).padding(.top, 25)
            ZStack {
                Text("iSayItForward").font(.custom("Kodchasan-Bold", size: 38)).kerning(5).foregroundColor(titleStrokeColor).offset(x: 1, y: 1.5)
                Text("iSayItForward").font(.custom("Kodchasan-Bold", size: 38)).kerning(5).foregroundColor(titleFillColor)
            }.shadow(color: .black.opacity(0.25), radius: 3, y: 2)
            Text("The Ultimate Way to Express Yourself").font(.custom("Kodchasan-Bold", size: 16)).kerning(0.5).foregroundColor(.black.opacity(0.7)).padding(.bottom, 10)
        }
    }

    // MARK: - Welcome Card
    private var welcomeCard: some View {
        VStack(spacing: 6) {
            Text("Welcome to iSIF, \(displayName.isEmpty ? "User" : displayName).").font(.custom("Kodchasan-SemiBold", size: 18)).foregroundColor(.black.opacity(0.85))
            Text("Choose an option below to get started.").font(.custom("Kodchasan-Regular", size: 15)).foregroundColor(.black.opacity(0.7))
        }
        .padding(20).frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 25).fill(Color.white.opacity(0.6))
                .overlay(ZStack {
                    RoundedRectangle(cornerRadius: 25).stroke(Color.white.opacity(0.8), lineWidth: 1.5)
                    RoundedRectangle(cornerRadius: 25).stroke(Color.black.opacity(0.15), lineWidth: 0.8)
                }).shadow(color: .black.opacity(0.05), radius: 3, y: 2)
        )
        .padding(.horizontal, 28)
    }

    // MARK: - Feature Buttons
    private var featureButtons: some View {
        HStack(spacing: 15) {
            NavigationLink(destination: GettingStartedView().navigationBarHidden(true)) {
                VStack(spacing: 6) {
                    Image("Large FAB").resizable().scaledToFit().frame(width: 70, height: 70).offset(y: 8)
                    Text("Getting\nStarted").font(.custom("Kodchasan-Medium", size: 13)).multilineTextAlignment(.center).foregroundColor(.black.opacity(0.75))
                }.frame(width: 100, height: 100)
            }.buttonStyle(PlainButtonStyle())

            NavigationLink(destination: CreateSIFView().navigationBarHidden(true)) {
                VStack(spacing: 6) {
                    Image("Large FAB-1").resizable().scaledToFit().frame(width: 90, height: 90)
                    Text("CREATE\nA SIF").font(.custom("Kodchasan-Medium", size: 13)).multilineTextAlignment(.center).foregroundColor(.black.opacity(0.75))
                }.frame(width: 110, height: 110)
            }.buttonStyle(PlainButtonStyle())

            NavigationLink(destination: MySIFsView().navigationBarHidden(true)) {
                VStack(spacing: 6) {
                    Image("Large FAB-2").resizable().scaledToFit().frame(width: 90, height: 90)
                    Text("MANAGE\nMY SIF'S").font(.custom("Kodchasan-Medium", size: 13)).multilineTextAlignment(.center).foregroundColor(.black.opacity(0.75))
                }.frame(width: 110, height: 110)
            }.buttonStyle(PlainButtonStyle())
        }
        .padding(.top, 4)
    }

    // MARK: - Divider
    private var divider: some View {
        Rectangle().fill(Color.gray.opacity(0.6)).frame(height: 1.5).cornerRadius(1).padding(.horizontal, 40).padding(.top, 14).shadow(color: .black.opacity(0.15), radius: 1.5, y: 1)
    }

    // MARK: - Template Gallery
    private var templateGalleryCard: some View {
        NavigationLink(destination: TemplateGalleryView().navigationBarHidden(true)) {
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("SIF Template Gallery").font(.custom("Kodchasan-SemiBold", size: 16)).foregroundColor(.white).padding(.vertical, 10).padding(.horizontal, 15).background(Capsule().fill(Color(red: 0.15, green: 0.25, blue: 0.35)))
                    Text("Explore a variety of ready made templates designed to help you express yourself with style and speed.").font(.custom("Kodchasan-Regular", size: 14)).foregroundColor(.black.opacity(0.75)).multilineTextAlignment(.leading).lineLimit(3).padding(.leading, 15)
                }.frame(maxWidth: .infinity, alignment: .leading)
                Image("4 2").resizable().scaledToFit().frame(height: 70).colorMultiply(.gray).opacity(0.8).shadow(color: .black.opacity(0.4), radius: 3, y: 2)
            }
            .padding(.horizontal, 15).padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.8)).shadow(color: .black.opacity(0.05), radius: 3, y: 2))
            .padding(.horizontal, 28).padding(.top, 4)
        }.buttonStyle(PlainButtonStyle())
    }

    // MARK: - Schedule a SIF
    private var scheduleCard: some View {
        NavigationLink(destination: ScheduleSIFView().navigationBarHidden(true)) {
            HStack(alignment: .center, spacing: 10) {
                Image("5 1").resizable().scaledToFit().frame(height: 70).colorMultiply(.gray).opacity(0.8).shadow(color: .black.opacity(0.4), radius: 3, y: 2)
                VStack(alignment: .trailing, spacing: 5) {
                    Text("Schedule a SIF").font(.custom("Kodchasan-SemiBold", size: 16)).foregroundColor(.white).padding(.vertical, 10).padding(.horizontal, 15).background(Capsule().fill(Color(red: 0.15, green: 0.25, blue: 0.35)))
                    Text("Never forget to send greetings on that special day again.").font(.custom("Kodchasan-Regular", size: 14)).foregroundColor(.black.opacity(0.75)).multilineTextAlignment(.trailing).lineLimit(3).padding(.trailing, 15)
                }.frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 15).padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.8)).shadow(color: .black.opacity(0.05), radius: 3, y: 2))
            .padding(.horizontal, 28).padding(.top, 6)
        }.buttonStyle(PlainButtonStyle())
    }

    // MARK: - Load user name
    private func loadUser() {
        if let user = Auth.auth().currentUser {
            displayName = user.displayName ?? user.email?.components(separatedBy: "@").first?.capitalized ?? ""
        }
    }
}

// MARK: - Supporting Types
private enum Tab { case home, compose, profile, schedule, settings }

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
    DashboardView()
        .environmentObject(AuthState())
}
