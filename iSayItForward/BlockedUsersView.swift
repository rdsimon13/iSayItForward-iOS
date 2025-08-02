import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct BlockedUsersView: View {
    @StateObject private var contentSafetyManager = ContentSafetyManager()
    
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var userToUnblock: BlockedUser?
    @State private var showingUnblockConfirmation = false
    
    var body: some View {
        ZStack {
            Color.mainAppGradient.ignoresSafeArea()
            
            VStack(spacing: 0) {
                if contentSafetyManager.isLoading {
                    ProgressView("Loading blocked users...")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if contentSafetyManager.blockedUsers.isEmpty {
                    EmptyBlockedUsersView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(contentSafetyManager.blockedUsers) { blockedUser in
                                BlockedUserRowView(
                                    blockedUser: blockedUser,
                                    onUnblock: {
                                        userToUnblock = blockedUser
                                        showingUnblockConfirmation = true
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationTitle("Blocked Users")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            Task {
                await contentSafetyManager.fetchBlockedUsers()
            }
        }
        .refreshable {
            await contentSafetyManager.fetchBlockedUsers()
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .alert("Unblock User", isPresented: $showingUnblockConfirmation) {
            Button("Unblock", role: .destructive) {
                if let user = userToUnblock {
                    unblockUser(user)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to unblock this user? You will start seeing their content again.")
        }
        .onReceive(contentSafetyManager.$errorMessage) { error in
            if let error = error {
                errorMessage = error
                showingErrorAlert = true
            }
        }
    }
    
    private func unblockUser(_ blockedUser: BlockedUser) {
        Task {
            do {
                try await contentSafetyManager.unblockUser(userUid: blockedUser.blockedUid)
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingErrorAlert = true
                }
            }
        }
    }
}

// MARK: - Blocked User Row View

struct BlockedUserRowView: View {
    let blockedUser: BlockedUser
    let onUnblock: () -> Void
    
    @State private var userName: String = "Unknown User"
    @State private var userEmail: String = ""
    
    private let db = Firestore.firestore()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(userName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if !userEmail.isEmpty {
                        Text(userEmail)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button("Unblock") {
                    onUnblock()
                }
                .buttonStyle(SecondaryActionButtonStyle())
                .controlSize(.small)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Blocked: \(blockedUser.blockedDate.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let reason = blockedUser.reason, !reason.isEmpty {
                    Text("Reason: \(reason)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding()
        .background(.white.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 3, y: 1)
        .onAppear {
            fetchUserInfo()
        }
    }
    
    private func fetchUserInfo() {
        db.collection("users").document(blockedUser.blockedUid).getDocument { snapshot, error in
            if let document = snapshot, document.exists {
                DispatchQueue.main.async {
                    self.userName = document.data()?["name"] as? String ?? "Unknown User"
                    self.userEmail = document.data()?["email"] as? String ?? ""
                }
            }
        }
    }
}

// MARK: - Empty State View

struct EmptyBlockedUsersView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.badge.minus")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.6))
            
            Text("No Blocked Users")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Users you block will appear here. You can unblock them at any time.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}

// MARK: - Block User Action View

struct BlockUserActionView: View {
    let userUid: String
    let userName: String
    let onDismiss: () -> Void
    let onBlock: () -> Void
    
    @StateObject private var contentSafetyManager = ContentSafetyManager()
    
    @State private var reason: String = ""
    @State private var isBlocking = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    private let maxReasonLength = 200
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.mainAppGradient.ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 20) {
                    
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Block User")
                            .font(.title2.weight(.bold))
                            .foregroundColor(.white)
                        
                        Text("Blocking \(userName) will prevent you from seeing their content.")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding()
                    
                    // Reason Input
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Reason (Optional)")
                            .font(.headline)
                            .foregroundColor(Color.brandDarkBlue)
                        
                        Text("Please provide a reason for blocking this user.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextEditor(text: $reason)
                            .frame(minHeight: 100)
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        
                        HStack {
                            Spacer()
                            Text("\(reason.count)/\(maxReasonLength)")
                                .font(.caption)
                                .foregroundColor(reason.count > maxReasonLength ? .red : .secondary)
                        }
                    }
                    .padding()
                    .background(.white.opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
                    
                    // Block Button
                    Button(action: blockUser) {
                        HStack {
                            if isBlocking {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "person.badge.minus")
                            }
                            Text(isBlocking ? "Blocking..." : "Block User")
                        }
                    }
                    .buttonStyle(PrimaryActionButtonStyle())
                    .disabled(isBlocking || reason.count > maxReasonLength)
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onDismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func blockUser() {
        guard !isBlocking else { return }
        
        isBlocking = true
        
        Task {
            do {
                try await contentSafetyManager.blockUser(
                    userUid: userUid,
                    reason: reason.trimmingCharacters(in: .whitespacesAndNewlines)
                )
                
                await MainActor.run {
                    isBlocking = false
                    onBlock()
                }
            } catch {
                await MainActor.run {
                    isBlocking = false
                    errorMessage = error.localizedDescription
                    showingErrorAlert = true
                }
            }
        }
    }
}

// MARK: - Preview

struct BlockedUsersView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            BlockedUsersView()
        }
    }
}