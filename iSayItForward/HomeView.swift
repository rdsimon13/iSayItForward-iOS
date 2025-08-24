import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// MARK: - HomeLaunchpadView must be defined first
private struct HomeLaunchpadView: View {
    @State private var userName: String = "User"
    @StateObject private var notificationService = NotificationService.shared
    @StateObject private var managerService = SIFManagerService.shared

    var body: some View {
        ZStack {
            Color.mainAppGradient.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    Text("Welcome to iSIF, \(userName).\nChoose an option below to get started.")
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.white.opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)

                    // Quick Stats Section
                    if !managerService.sentSIFs.isEmpty {
                        HStack(spacing: 12) {
                            QuickStatCard(
                                title: "Sent",
                                value: "\(managerService.sentSIFs.count)",
                                icon: "paperplane.fill",
                                color: .blue
                            )
                            
                            QuickStatCard(
                                title: "Delivered",
                                value: "\(managerService.sentSIFs.filter { $0.deliveryStatus == .delivered }.count)",
                                icon: "checkmark.circle.fill",
                                color: .green
                            )
                            
                            QuickStatCard(
                                title: "Scheduled",
                                value: "\(managerService.sentSIFs.filter { $0.deliveryStatus == .scheduled }.count)",
                                icon: "calendar",
                                color: .orange
                            )
                        }
                        .padding(.horizontal, 4)
                    }

                    HStack(spacing: 16) {
                        NavigationLink(destination: CreateSIFView()) {
                            HomeActionButton(iconName: "square.and.pencil", text: "CREATE A SIF")
                        }
                        
                        NavigationLink(destination: MySIFsView()) {
                            HomeActionButton(iconName: "envelope", text: "MANAGE SIFs")
                        }
                        
                        NavigationLink(destination: QRCodeScannerMainView()) {
                            HomeActionButton(iconName: "qrcode.viewfinder", text: "QR SCANNER")
                        }
                    }

                    NavigationLink(destination: SIFManagementView()) {
                        PromoCard(title: "SIF Management Center",
                                  description: "Organize your SIFs with folders, search, and batch operations. Keep track of all your messages in one place.",
                                  iconName: "folder.fill.badge.gearshape")
                    }

                    NavigationLink(destination: TemplateGalleryView()) {
                        PromoCard(title: "SIF Template Gallery",
                                  description: "Explore a variety of ready made templates designed to help you express yourself with style and speed.",
                                  iconName: "photo.on.rectangle.angled")
                    }

                    NavigationLink(destination: CreateSIFView()) {
                        PromoCard(title: "Schedule a SIF",
                                  description: "Never forget to send greetings on that special day ever again. Schedule your SIF for future delivery today!",
                                  iconName: "calendar")
                    }

                    // Recent Activity Section
                    if !managerService.sentSIFs.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Activity")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 4)
                            
                            ForEach(Array(managerService.sentSIFs.prefix(3))) { sif in
                                NavigationLink(destination: SIFDetailView(sif: sif)) {
                                    RecentActivityCard(sif: sif)
                                }
                            }
                        }
                    }

                    Spacer()
                }
                .padding()
            }
            .onAppear {
                fetchUserData()
                Task {
                    await notificationService.checkNotificationPermissions()
                    await managerService.fetchSIFs()
                }
            }
            .navigationTitle("Home")
            .navigationBarHidden(true)
        }
    }

    func fetchUserData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let document = snapshot, document.exists {
                self.userName = document.data()?["name"] as? String ?? "User"
            }
        }
    }
}

private struct QuickStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.white.opacity(0.15))
        .cornerRadius(12)
    }
}

private struct RecentActivityCard: View {
    let sif: SIFItem
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: sif.deliveryStatus.systemImageName)
                .font(.title2)
                .foregroundColor(statusColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(sif.subject)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text("To: \(sif.recipients.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
                
                Text(sif.createdDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            Text(sif.deliveryStatus.displayName)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.2))
                .foregroundColor(statusColor)
                .clipShape(Capsule())
        }
        .padding()
        .background(.white.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var statusColor: Color {
        switch sif.deliveryStatus {
        case .delivered:
            return .green
        case .failed, .cancelled, .expired:
            return .red
        case .pending, .scheduled:
            return .orange
        case .processing, .uploading:
            return .blue
        }
    }
}

private struct HomeActionButton: View {
    let iconName: String
    let text: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: iconName)
                .font(.largeTitle)
                .frame(width: 60, height: 60)
                .background(.white.opacity(0.85))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
            Text(text)
                .font(.caption)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
        }
        .foregroundColor(Color.brandDarkBlue)
        .frame(maxWidth: .infinity)
    }
}

private struct PromoCard: View {
    let title: String
    let description: String
    let iconName: String

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                Text(description)
                    .font(.caption)
            }
            Spacer()
            Image(systemName: iconName)
                .font(.system(size: 40, weight: .light))
        }
        .padding(20)
        .background(.white.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .foregroundColor(Color.brandDarkBlue)
        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
    }
}

// MARK: - Main HomeView
struct HomeView: View {
    var body: some View {
        if #available(iOS 16.0, *) {
            TabView {
                NavigationStack {
                    HomeLaunchpadView()
                }
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }

                CreateSIFView()
                    .tabItem {
                        Image(systemName: "square.and.pencil")
                        Text("Send SIF")
                    }

                MySIFsView()
                    .tabItem {
                        Image(systemName: "envelope.fill")
                        Text("My SIFs")
                    }

                QRCodeScannerMainView()
                    .tabItem {
                        Image(systemName: "qrcode.viewfinder")
                        Text("QR Scanner")
                    }

                ProfileView()
                    .tabItem {
                        Image(systemName: "person.crop.circle")
                        Text("Profile")
                    }
            }
            .accentColor(Color.brandDarkBlue)
            .onAppear {
                // Request notification permissions on first launch
                Task {
                    await NotificationService.shared.requestNotificationPermissions()
                }
            }
        } else {
            Text("Home requires iOS 16.0 or newer.")
                .multilineTextAlignment(.center)
                .padding()
                .foregroundColor(.red)
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
