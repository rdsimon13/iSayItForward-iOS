import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct DashboardView: View {
    // MARK: - Environment Objects
    @EnvironmentObject var router: TabRouter
    @EnvironmentObject var authState: AuthState

    // MARK: - Local State
    @State private var displayName: String = ""
    @State private var sentSIFs: [SIF] = []
    @State private var receivedSIFs: [SIF] = []
    @State private var isLoadingSIFs = false

    // MARK: - Firestore Service
    private let sifService = SIFService()

    // MARK: - Color Theme
    let titleFillColor = Color(hex: "E6F4F5")
    let titleStrokeColor = Color(hex: "132E37")

    var body: some View {
        NavigationStack {
            ZStack {
                // MARK: - Background
                RadialGradient(
                    gradient: Gradient(stops: [
                        .init(color: .white, location: 0.0),
                        .init(color: Color(red: 0.0, green: 0.732, blue: 1.2), location: 1.0)
                    ]),
                    center: .top,
                    startRadius: 0,
                    endRadius: UIScreen.main.bounds.height
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            headerSection
                            welcomeCard
                            featureButtons
                            divider
                            recentSIFsSection
                            templateGalleryCard
                            scheduleCard
                            Spacer(minLength: 10)
                        }
                        .padding(.top, 10)
                        .refreshable { fetchSIFs() }
                    }

                    // MARK: - Bottom Navigation Bar
                    BottomNavBar(
                        selectedTab: $router.selectedTab,
                        isVisible: .constant(true)
                    )
                    .environmentObject(router)
                    .environmentObject(authState)
                    .padding(.bottom, 5)
                }
                .onAppear {
                    loadUser()
                    fetchSIFs()
                }
                .onChange(of: authState.isUserLoggedIn) { _ in
                    loadUser()
                    fetchSIFs()
                }
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image("isiFLogo")
                .resizable()
                .scaledToFit()
                .frame(height: 150)
                .shadow(color: .black.opacity(0.25), radius: 5, y: 3)
                .padding(.top, 25)

            ZStack {
                Text("iSayItForward")
                    .font(.custom("AvenirNext-Bold", size: 38))
                    .kerning(4)
                    .foregroundColor(titleStrokeColor)
                    .offset(x: 1, y: 1.5)
                Text("iSayItForward")
                    .font(.custom("AvenirNext-Bold", size: 38))
                    .kerning(4)
                    .foregroundColor(titleFillColor)
            }
            .shadow(color: .black.opacity(0.25), radius: 3, y: 2)

            Text("The Ultimate Way to Express Yourself")
                .font(.custom("AvenirNext-DemiBold", size: 16))
                .foregroundColor(.black.opacity(0.75))
                .padding(.bottom, 10)
        }
    }

    // MARK: - Welcome Card
    private var welcomeCard: some View {
        VStack(spacing: 6) {
            Text("Welcome to iSIF, \(displayName.isEmpty ? "User" : displayName).")
                .font(.custom("AvenirNext-DemiBold", size: 18))
                .foregroundColor(.black.opacity(0.85))
            Text("Choose an option below to get started.")
                .font(.custom("AvenirNext-Regular", size: 15))
                .foregroundColor(.black.opacity(0.7))
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.white.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Color.white.opacity(0.8), lineWidth: 1.5)
                        .shadow(color: .black.opacity(0.05), radius: 3, y: 2)
                )
        )
        .padding(.horizontal, 28)
    }

    // MARK: - Feature Buttons
    private var featureButtons: some View {
        HStack(spacing: 25) {
            // 🟦 Getting Started
            NavigationLink(destination: GettingStartedView()
                .environmentObject(router)
                .environmentObject(authState)) {
                featureButton(icon: "Large FAB", label: "Getting\nStarted", width: 75)
                    .offset(x: 20, y: 20)
            }

            // 🟧 Create SIF
            Button {
                router.selectedTab = .compose
            } label: {
                featureButton(icon: "Large FAB-1", label: "CREATE\nA SIF", width: 85)
            }

            // 🟣 Manage My SIFs
            NavigationLink(destination: SIFInboxView()
                .environmentObject(router)
                .environmentObject(authState)) {
                featureButton(icon: "Large FAB-2", label: "MANAGE\nMY SIF'S", width: 85)
            }
        }
        .padding(.top, 4)
    }

    private func featureButton(icon: String, label: String, width: CGFloat) -> some View {
        VStack(spacing: 6) {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: width, height: width)
                .shadow(color: .black.opacity(0.25), radius: 3, y: 1)
            Text(label)
                .font(.custom("AvenirNext-Medium", size: 13))
                .multilineTextAlignment(.center)
                .foregroundColor(.black.opacity(0.75))
        }
        .frame(width: 100, height: 100)
    }

    // MARK: - Divider
    private var divider: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.6))
            .frame(height: 1.5)
            .cornerRadius(1)
            .padding(.horizontal, 40)
            .padding(.top, 14)
            .shadow(color: .black.opacity(0.15), radius: 1.5, y: 1)
    }

    // MARK: - Recent SIFs Section
    private var recentSIFsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Recent SIFs")
                .font(.custom("AvenirNext-DemiBold", size: 18))
                .foregroundColor(.black.opacity(0.8))
                .padding(.leading, 30)
                .padding(.top, 6)

            if isLoadingSIFs {
                ProgressView("Loading SIFs...")
                    .padding()
            } else if sentSIFs.isEmpty && receivedSIFs.isEmpty {
                Text("You haven’t sent or received any SIFs yet.")
                    .font(.custom("AvenirNext-Regular", size: 15))
                    .foregroundColor(.gray)
                    .padding(.leading, 30)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    if !sentSIFs.isEmpty {
                        Text("📤 Sent")
                            .font(.custom("AvenirNext-Medium", size: 15))
                            .padding(.leading, 30)
                            .foregroundColor(.black.opacity(0.7))

                        ForEach(sentSIFs.prefix(5)) { sif in
                            sifPreview(sif)
                        }
                    }

                    if !receivedSIFs.isEmpty {
                        Text("📥 Received")
                            .font(.custom("AvenirNext-Medium", size: 15))
                            .padding(.leading, 30)
                            .foregroundColor(.black.opacity(0.7))

                        ForEach(receivedSIFs.prefix(5)) { sif in
                            sifPreview(sif)
                        }
                    }
                }
            }
        }
        .padding(.bottom, 15)
    }

    private func sifPreview(_ sif: SIF) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(sif.message)
                .font(.custom("AvenirNext-Regular", size: 14))
                .foregroundColor(.black.opacity(0.9))
                .lineLimit(2)
            Text("→ \(sif.recipients.map { $0.name }.joined(separator: ", "))")
                .font(.custom("AvenirNext-Regular", size: 12))
                .foregroundColor(.gray)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.7))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
        .padding(.horizontal, 30)
    }

    // MARK: - Template Gallery Card
    private var templateGalleryCard: some View {
        NavigationLink(destination: TemplateGalleryView(selectedTemplate: .constant(nil))
            .environmentObject(router)
            .environmentObject(authState)) {
            middleCard(
                title: "SIF Template Gallery",
                subtitle: "Explore ready-made templates to express yourself with style.",
                imageName: "4 2"
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Schedule a SIF Card
    private var scheduleCard: some View {
        NavigationLink(destination: ScheduleSIFView()
            .environmentObject(router)
            .environmentObject(authState)) {
            middleCard(
                title: "Schedule a SIF",
                subtitle: "Never forget to send greetings on that special day again.",
                imageName: "5 1"
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Shared Middle Card
    private func middleCard(title: String, subtitle: String, imageName: String) -> some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.custom("AvenirNext-DemiBold", size: 16))
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 15)
                    .background(Capsule().fill(Color(red: 0.15, green: 0.25, blue: 0.35)))
                Text(subtitle)
                    .font(.custom("AvenirNext-Regular", size: 14))
                    .foregroundColor(.black.opacity(0.8))
                    .lineLimit(3)
                    .padding(.leading, 15)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(height: 70)
                .colorMultiply(Color.black.opacity(0.6))
                .shadow(color: .black.opacity(0.4), radius: 3, y: 2)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.8))
                .shadow(color: .black.opacity(0.05), radius: 3, y: 2)
        )
        .padding(.horizontal, 28)
    }

    // MARK: - Load User Info
    private func loadUser() {
        if let user = Auth.auth().currentUser {
            displayName = user.displayName ??
                user.email?.components(separatedBy: "@").first?.capitalized ?? "User"
            print("👤 Dashboard loaded for: \(user.email ?? user.uid)")
        } else {
            displayName = ""
            print("⚠️ No active Firebase user.")
        }
    }

    // MARK: - Fetch SIFs
    private func fetchSIFs() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("⚠️ No user logged in; skipping SIF fetch.")
            return
        }
        isLoadingSIFs = true

        Task {
            do {
                let allSIFs = try await sifService.fetchUserSIFs(for: userId)
                sentSIFs = allSIFs
                print("✅ Loaded \(sentSIFs.count) sent SIFs for user.")
            } catch {
                print("❌ Failed to load SIFs: \(error.localizedDescription)")
            }
            isLoadingSIFs = false
        }
    }
}

// MARK: - Preview
#Preview {
    DashboardView()
        .environmentObject(TabRouter())
        .environmentObject(AuthState())
}
