import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct MySIFsView: View {
    @StateObject private var subscriptionManager = SubscriptionManager()
    @State private var sifs: [SIFItem] = []
    @State private var isLoading = false
    @State private var showingTierSelection = false

    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                ZStack {
                    Color.mainAppGradient.ignoresSafeArea()

                    ScrollView {
                        VStack(spacing: 20) {
                            // Usage stats card
                            if let user = subscriptionManager.currentUser {
                                ModernCard {
                                    VStack(spacing: 16) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Your SIFs")
                                                    .font(.system(size: 20, weight: .bold))
                                                    .foregroundColor(.neutralGray800)
                                                
                                                Text("\(sifs.count) total sent")
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundColor(.neutralGray600)
                                            }
                                            
                                            Spacer()
                                            
                                            TierBadge(tier: user.effectiveTier, style: .detailed)
                                        }
                                        
                                        // Usage limit info
                                        if user.effectiveTier.maxSIFsPerMonth != -1 {
                                            UsageLimitWarning(
                                                currentUsage: sifs.count,
                                                limit: user.effectiveTier.maxSIFsPerMonth,
                                                title: "Monthly SIF Limit",
                                                upgradeAction: {
                                                    showingTierSelection = true
                                                }
                                            )
                                        }
                                    }
                                    .padding(20)
                                }
                            }
                            
                            // Ad banner (if applicable)
                            AdBannerView(subscriptionManager: subscriptionManager)

                            // SIFs list
                            if isLoading {
                                LoadingView(message: "Loading your SIFs...")
                                    .frame(height: 200)
                            } else if sifs.isEmpty {
                                EmptyStateView(
                                    iconName: "envelope.badge",
                                    title: "No SIFs Yet",
                                    description: "You haven't sent any SIFs yet. Create your first one to get started!",
                                    actionText: "Create SIF",
                                    action: {
                                        // Navigate to create SIF - would need coordination with parent
                                    }
                                )
                                .frame(height: 300)
                            } else {
                                LazyVStack(spacing: 12) {
                                    ForEach(sifs) { sif in
                                        NavigationLink(destination: SIFDetailView(sif: sif)) {
                                            SIFRowCard(sif: sif)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                            
                            Spacer(minLength: 40)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                }
                .navigationTitle("My SIFs")
                .navigationBarTitleDisplayMode(.large)
                .onAppear {
                    fetchSIFs()
                    if let uid = Auth.auth().currentUser?.uid {
                        Task {
                            await subscriptionManager.fetchUserData(uid: uid)
                        }
                    }
                }
                .refreshable {
                    fetchSIFs()
                }
            }
            .sheet(isPresented: $showingTierSelection) {
                TierSelectionView(isUpgradeFlow: true)
                    .environmentObject(subscriptionManager)
            }
        } else {
            Text("This feature requires iOS 16.0 or newer.")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding()
        }
    }

    func fetchSIFs() {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("User is not logged in.")
            return
        }

        isLoading = true
        let db = Firestore.firestore()
        db.collection("sifs").whereField("authorUid", isEqualTo: uid)
            .order(by: "createdDate", descending: true)
            .getDocuments { snapshot, error in
                defer { isLoading = false }
                
                if let error = error {
                    print("Error fetching SIFs: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents else {
                    print("No documents found.")
                    return
                }

                self.sifs = documents.compactMap { doc -> SIFItem? in
                    try? doc.data(as: SIFItem.self)
                }
            }
    }
}

// MARK: - SIF Row Card Component
private struct SIFRowCard: View {
    let sif: SIFItem
    
    var body: some View {
        ModernCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(sif.subject.isEmpty ? "No Subject" : sif.subject)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.neutralGray800)
                            .lineLimit(2)
                        
                        Text("To: \(sif.recipients.joined(separator: ", "))")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.neutralGray600)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.neutralGray400)
                }
                
                Divider()
                
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 12))
                            .foregroundColor(.neutralGray500)
                        
                        Text("Scheduled: \(sif.scheduledDate.formatted(date: .abbreviated, time: .shortened))")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.neutralGray500)
                    }
                    
                    Spacer()
                    
                    // Status indicator
                    HStack(spacing: 4) {
                        Circle()
                            .fill(sif.scheduledDate > Date() ? Color.warningYellow : Color.successGreen)
                            .frame(width: 6, height: 6)
                        
                        Text(sif.scheduledDate > Date() ? "Scheduled" : "Sent")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(sif.scheduledDate > Date() ? Color.warningYellow : Color.successGreen)
                    }
                }
            }
            .padding(16)
        }
    }
}

struct MySIFsView_Previews: PreviewProvider {
    static var previews: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                MySIFsView()
            }
        } else {
            Text("Preview not available below iOS 16.")
        }
    }
}
