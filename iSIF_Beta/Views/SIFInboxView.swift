import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// MARK: - SIF Inbox View
struct SIFInboxView: View {
    @EnvironmentObject var router: TabRouter
    @EnvironmentObject var authState: AuthState
    @StateObject private var sifService = SIFDataManager()

    @State private var sifs: [SIF] = []
    @State private var searchText = ""
    @State private var filter: SIFFilter = .all
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var listener: ListenerRegistration? = nil

    // MARK: - Enum for filtering
    enum SIFFilter: String, CaseIterable {
        case all = "All"
        case sent = "Sent"
        case scheduled = "Scheduled"
        case delivered = "Delivered"
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0.95),
                    Color(red: 0.0, green: 0.7, blue: 1.0).opacity(0.9)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                if isLoading {
                    ProgressView("Loading your SIFs…")
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .font(.custom("AvenirNext-Regular", size: 16))
                        .padding(.top, 50)
                } else if let errorMessage = errorMessage {
                    Text("⚠️ \(errorMessage)")
                        .foregroundColor(.red)
                        .padding()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            headerSection
                            blurredContainer { counterBar }
                                .padding(.horizontal)
                            blurredContainer { filterBar }
                                .padding(.horizontal)
                            searchBar
                            contentSection
                                .padding(.top, 5)
                        }
                        .padding(.top, 10)
                    }
                }

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
        .task { await loadUserSIFs() }
        .onDisappear {
            listener?.remove()
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 4) {
            Text("📬 SIF Inbox")
                .font(.custom("AvenirNext-Bold", size: 28))
                .foregroundColor(Color(hex: "132E37"))
            Text("Your sent, delivered, and scheduled SIFs")
                .font(.custom("AvenirNext-Regular", size: 15))
                .foregroundColor(.black.opacity(0.6))
        }
    }

    // MARK: - Counter Bar
    private var counterBar: some View {
        HStack(spacing: 14) {
            counterTile(label: "Total", count: sifs.count)
            counterTile(label: "Delivered", count: deliveredCount)
            counterTile(label: "Scheduled", count: scheduledCount)
        }
    }

    private func counterTile(label: String, count: Int) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.custom("AvenirNext-DemiBold", size: 20))
                .foregroundColor(Color(hex: "132E37"))
            Text(label)
                .font(.custom("AvenirNext-Regular", size: 12))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .onTapGesture {
            switch label.lowercased() {
            case "delivered": filter = .delivered
            case "scheduled": filter = .scheduled
            case "total": filter = .all
            default: break
            }
        }
        .animation(.easeInOut, value: filter)
    }

    private var deliveredCount: Int {
        sifs.filter { $0.status.lowercased() == "delivered" }.count
    }

    private var scheduledCount: Int {
        sifs.filter { $0.isScheduled }.count
    }

    // MARK: - Filter Bar
    private var filterBar: some View {
        HStack(spacing: 10) {
            ForEach(SIFFilter.allCases, id: \.self) { f in
                filterButton(for: f)
            }
        }
        .padding(.vertical, 8)
    }

    private func filterButton(for f: SIFFilter) -> some View {
        let isSelected = filter == f
        return Button {
            withAnimation(.easeInOut(duration: 0.25)) { filter = f }
        } label: {
            Text(f.rawValue)
                .font(.custom("AvenirNext-Medium", size: 14))
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
                .background(
                    Capsule().fill(
                        isSelected
                        ? AnyShapeStyle(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.8), Color.cyan.opacity(0.85)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        : AnyShapeStyle(.ultraThinMaterial)
                    )
                )
                .foregroundColor(isSelected ? .white : .black.opacity(0.75))
        }
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray.opacity(0.7))
            TextField("Search SIF history...", text: $searchText)
                .font(.custom("AvenirNext-Regular", size: 15))
                .autocorrectionDisabled()
        }
        .padding(.vertical, 10)
        .padding(.horizontal)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .padding(.horizontal)
    }

    // MARK: - Content Section
    private var contentSection: some View {
        Group {
            if filteredSIFs.isEmpty {
                Text("No SIFs match your filters.")
                    .font(.custom("AvenirNext-Regular", size: 15))
                    .foregroundColor(.gray)
                    .padding(.top, 80)
            } else {
                LazyVStack(spacing: 14) {
                    ForEach(filteredSIFs) { sif in
                        SIFRowView(sif: sif)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 100)
            }
        }
    }

    // MARK: - Filtered Data
    private var filteredSIFs: [SIF] {
        sifs.filter { sif in
            let matchesSearch = searchText.isEmpty || sif.message.localizedCaseInsensitiveContains(searchText)
            let matchesFilter: Bool = {
                switch filter {
                case .all: return true
                case .sent: return sif.status.lowercased() == "sent"
                case .scheduled: return sif.isScheduled
                case .delivered: return sif.status.lowercased() == "delivered"
                }
            }()
            return matchesSearch && matchesFilter
        }
    }

    // MARK: - Data Loading
    private func loadUserSIFs() async {
        guard let user = Auth.auth().currentUser else {
            errorMessage = "User not authenticated."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            sifs = try await sifService.fetchUserSIFs(for: user.uid)
            print("📬 Loaded \(sifs.count) SIFs")

            // Optional: Real-time updates
            listener?.remove()
            listener = sifService.observeUserSIFs(for: user.uid) { newSIFs in
                self.sifs = newSIFs
            }

        } catch {
            errorMessage = "Failed to load SIFs: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Frosted Container
    private func blurredContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
            content().padding(8)
        }
    }
}

// MARK: - SIF Row View
struct SIFRowView: View {
    let sif: SIF

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(sif.initials)
                        .font(.custom("AvenirNext-Bold", size: 14))
                        .foregroundColor(.gray)
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Circle()
                        .fill(sif.statusColor)
                        .frame(width: 8, height: 8)
                    Text(sif.displayName)
                        .font(.custom("AvenirNext-DemiBold", size: 14))
                    Spacer()
                    Text(sif.formattedDate)
                        .font(.custom("AvenirNext-Regular", size: 12))
                        .foregroundColor(.gray)
                }

                Text(sif.subject)
                    .font(.custom("AvenirNext-DemiBold", size: 15))
                    .foregroundColor(.black)

                Text(sif.message)
                    .font(.custom("AvenirNext-Regular", size: 13))
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 3, y: 1)
        )
    }
}

// MARK: - SIF Display Helpers
extension SIF {
    var displayName: String {
        recipients.first?.name ?? "Unknown"
    }

    var initials: String {
        displayName.split(separator: " ").compactMap { $0.first }.prefix(2).map(String.init).joined()
    }

    var statusColor: Color {
        switch status.lowercased() {
        case "sent": return .blue
        case "scheduled": return .orange
        case "delivered": return .green
        default: return .gray
        }
    }

    var formattedDate: String {
        createdAt.formatted(date: .abbreviated, time: .omitted)
    }
}

// MARK: - Preview
#Preview {
    SIFInboxView()
        .environmentObject(AuthState())
        .environmentObject(TabRouter())
}
