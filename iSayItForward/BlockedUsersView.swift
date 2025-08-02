import SwiftUI

struct BlockedUsersView: View {
    @StateObject private var blockingService = BlockingService()
    @State private var blockedUsers: [BlockedUserDetail] = []
    @State private var isLoading = true
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var userToUnblock: BlockedUserDetail?
    
    var body: some View {
        ZStack {
            Color.mainAppGradient.ignoresSafeArea()
            
            VStack {
                if isLoading {
                    ProgressView("Loading blocked users...")
                        .foregroundColor(.white)
                } else if blockedUsers.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("No Blocked Users")
                            .font(.title2.weight(.semibold))
                            .foregroundColor(.white)
                        
                        Text("You haven't blocked any users yet.")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(blockedUsers, id: \.blockRecord.id) { blockedUser in
                            BlockedUserRow(
                                blockedUser: blockedUser,
                                onUnblock: {
                                    userToUnblock = blockedUser
                                    showingAlert = true
                                }
                            )
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Blocked Users")
            .onAppear {
                loadBlockedUsers()
            }
            .alert("Unblock User", isPresented: $showingAlert) {
                Button("Cancel", role: .cancel) {
                    userToUnblock = nil
                }
                Button("Unblock", role: .destructive) {
                    if let user = userToUnblock {
                        unblockUser(user)
                    }
                }
            } message: {
                if let user = userToUnblock {
                    Text("Are you sure you want to unblock \(user.userName)? They will be able to interact with your content again.")
                }
            }
            .alert("Error", isPresented: .constant(!alertMessage.isEmpty)) {
                Button("OK") {
                    alertMessage = ""
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func loadBlockedUsers() {
        isLoading = true
        
        Task {
            do {
                let users = try await blockingService.getBlockedUsersWithDetails()
                await MainActor.run {
                    self.blockedUsers = users
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.alertMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    private func unblockUser(_ blockedUser: BlockedUserDetail) {
        Task {
            do {
                try await blockingService.unblockUser(blockedUser.blockRecord.blockedUserId)
                await MainActor.run {
                    blockedUsers.removeAll { $0.blockRecord.id == blockedUser.blockRecord.id }
                    userToUnblock = nil
                }
            } catch {
                await MainActor.run {
                    alertMessage = error.localizedDescription
                    userToUnblock = nil
                }
            }
        }
    }
}

struct BlockedUserRow: View {
    let blockedUser: BlockedUserDetail
    let onUnblock: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(blockedUser.userName)
                    .font(.headline)
                    .foregroundColor(Color.brandDarkBlue)
                
                if !blockedUser.userEmail.isEmpty {
                    Text(blockedUser.userEmail)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    if let reason = blockedUser.blockRecord.reason {
                        Text("Reason: \(reason.displayName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("Blocked \(blockedUser.blockRecord.timestamp.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button("Unblock") {
                onUnblock()
            }
            .buttonStyle(.bordered)
            .foregroundColor(.red)
        }
        .padding(.vertical, 4)
    }
}

struct BlockedUsersView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            BlockedUsersView()
        }
    }
}