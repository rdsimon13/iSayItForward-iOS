import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ProfileView: View {
    @StateObject private var subscriptionManager = SubscriptionManager()
    @State private var showingTierSelection = false
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color.mainAppGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        Text("Profile")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.neutralGray800)
                            .padding(.top)

                        // User Avatar
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                            
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(.brandBlue)
                                .padding(20)
                        }
                        .frame(width: 120, height: 120)

                        // User Info Card
                        ModernCard {
                            VStack(spacing: 16) {
                                // User details
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "person.fill")
                                            .foregroundColor(.brandBlue)
                                            .frame(width: 20)
                                        Text(subscriptionManager.currentUser?.name ?? "User")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    
                                    Divider()
                                    
                                    HStack {
                                        Image(systemName: "envelope.fill")
                                            .foregroundColor(.brandBlue)
                                            .frame(width: 20)
                                        Text(subscriptionManager.currentUser?.email ?? "No email")
                                            .font(.system(size: 16, weight: .medium))
                                    }
                                }
                                
                                // Current tier section
                                VStack(spacing: 12) {
                                    Divider()
                                    
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Current Plan")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.neutralGray600)
                                            
                                            if let user = subscriptionManager.currentUser {
                                                TierBadge(tier: user.effectiveTier, style: .detailed)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        Button("Manage") {
                                            showingTierSelection = true
                                        }
                                        .buttonStyle(ModernSecondaryButtonStyle())
                                        .frame(width: 80, height: 32)
                                    }
                                }
                            }
                            .padding(20)
                        }
                        
                        // Tier benefits card
                        if let user = subscriptionManager.currentUser {
                            ModernCard {
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.brandGold)
                                        Text("Your Benefits")
                                            .font(.system(size: 18, weight: .semibold))
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        ForEach(user.effectiveTier.features, id: \.self) { feature in
                                            HStack(alignment: .top, spacing: 12) {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(.successGreen)
                                                    .frame(width: 16)
                                                
                                                Text(feature)
                                                    .font(.system(size: 14, weight: .medium))
                                                    .multilineTextAlignment(.leading)
                                                
                                                Spacer()
                                            }
                                        }
                                    }
                                    
                                    if user.effectiveTier != .pro {
                                        Button("Upgrade Plan") {
                                            showingTierSelection = true
                                        }
                                        .buttonStyle(ModernPrimaryButtonStyle(
                                            gradient: Color.tierGradient(for: .pro)
                                        ))
                                        .padding(.top, 8)
                                    }
                                }
                                .padding(20)
                            }
                        }
                        
                        // Usage stats (if available)
                        if let user = subscriptionManager.currentUser {
                            ModernCard {
                                VStack(spacing: 16) {
                                    HStack {
                                        Image(systemName: "chart.bar.fill")
                                            .foregroundColor(.brandBlue)
                                        Text("Usage Stats")
                                            .font(.system(size: 18, weight: .semibold))
                                        Spacer()
                                    }
                                    
                                    VStack(spacing: 12) {
                                        HStack {
                                            Text("Data Storage")
                                                .font(.system(size: 14, weight: .medium))
                                            Spacer()
                                            Text(user.effectiveTier.dataLimitMB == -1 ? "Unlimited" : "\(user.effectiveTier.dataLimitMB) MB")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.brandBlue)
                                        }
                                        
                                        HStack {
                                            Text("Monthly SIFs")
                                                .font(.system(size: 14, weight: .medium))
                                            Spacer()
                                            Text(user.effectiveTier.maxSIFsPerMonth == -1 ? "Unlimited" : "\(user.effectiveTier.maxSIFsPerMonth)")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.brandBlue)
                                        }
                                        
                                        HStack {
                                            Text("E-Signature")
                                                .font(.system(size: 14, weight: .medium))
                                            Spacer()
                                            Text(user.effectiveTier.allowsESignature ? "Available" : "Not Available")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(user.effectiveTier.allowsESignature ? .successGreen : .neutralGray500)
                                        }
                                    }
                                }
                                .padding(20)
                            }
                        }

                        Spacer()

                        // Logout button
                        Button("Log Out") {
                            handleLogout()
                        }
                        .buttonStyle(ModernSecondaryButtonStyle())
                        .foregroundColor(.errorRed)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingTierSelection) {
                TierSelectionView(isUpgradeFlow: true)
                    .environmentObject(subscriptionManager)
            }
            .alert("Logout Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                // Fetch user data when view appears
                if let uid = Auth.auth().currentUser?.uid {
                    Task {
                        await subscriptionManager.fetchUserData(uid: uid)
                    }
                }
            }
        }
    }
    
    private func handleLogout() {
        do {
            try Auth.auth().signOut()
        } catch let signOutError as NSError {
            alertMessage = "Error signing out: \(signOutError.localizedDescription)"
            showingAlert = true
        }
    }
}
