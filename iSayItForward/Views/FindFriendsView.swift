import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// MARK: - Friend Search View
struct FindFriendsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var service = FriendService()
    
    @State private var allUsers: [UserFriend] = []
    @State private var searchText = ""
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var sentRequests: Set<String> = []
    @State private var friends: [UserFriend] = []
    
    var body: some View {
        NavigationStack {
            ZStack {
                GradientTheme.welcomeBackground.ignoresSafeArea()
                
                VStack(spacing: 15) {
                    searchBar
                    
                    if isLoading {
                        ProgressView("Loading users...")
                            .padding(.top, 60)
                    } else if let error = errorMessage {
                        Text("⚠️ \(error)")
                            .foregroundColor(.red)
                            .padding()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredUsers) { user in
                                    userRow(user)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                        }
                    }
                }
                .padding(.top, 10)
            }
            .navigationTitle("Find Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .task {
                await loadData()
            }
        }
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Search users by name or email...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.custom("AvenirNext-Regular", size: 15))
        }
        .padding(.vertical, 10)
        .padding(.horizontal)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.9))
                .shadow(color: .black.opacity(0.1), radius: 3, y: 2)
        )
        .padding(.horizontal)
    }
    
    // MARK: - User Row
    private func userRow(_ user: UserFriend) -> some View {
        let alreadyFriend = friends.contains(where: { $0.id == user.id })
        let hasSentRequest = sentRequests.contains(user.id)
        let isCurrentUser = user.id == Auth.auth().currentUser?.uid
        
        return HStack(spacing: 12) {
            if let url = user.photoURL, let imageURL = URL(string: url) {
                AsyncImage(url: imageURL) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Circle().fill(Color.gray.opacity(0.3))
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 50, height: 50)
                    .overlay(Text(user.name.prefix(1)).foregroundColor(.white))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(user.name)
                    .font(.custom("AvenirNext-Medium", size: 16))
                Text(user.email)
                    .font(.custom("AvenirNext-Regular", size: 13))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            if isCurrentUser {
                Text("You")
                    .font(.custom("AvenirNext-Regular", size: 13))
                    .foregroundColor(.gray)
            } else if alreadyFriend {
                Text("Friends")
                    .font(.custom("AvenirNext-Regular", size: 13))
                    .foregroundColor(.green)
            } else if hasSentRequest {
                Text("Requested")
                    .font(.custom("AvenirNext-Regular", size: 13))
                    .foregroundColor(.orange)
            } else {
                Button {
                    Task { await sendFriendRequest(to: user) }
                } label: {
                    Text("Add Friend")
                        .font(.custom("AvenirNext-DemiBold", size: 13))
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(Capsule().fill(Color.blue.opacity(0.9)))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.95))
                .shadow(color: .black.opacity(0.1), radius: 3, y: 2)
        )
    }
    
    // MARK: - Filtered Users
    private var filteredUsers: [UserFriend] {
        if searchText.isEmpty { return allUsers }
        return allUsers.filter { user in
            user.name.localizedCaseInsensitiveContains(searchText) ||
            user.email.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    // MARK: - Data Load
    private func loadData() async {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not logged in."
            isLoading = false
            return
        }
        
        do {
            allUsers = try await service.fetchAllUsers(excluding: currentUserId)
            friends = try await service.fetchFriends(for: currentUserId)
            sentRequests = try await service.fetchSentRequests(for: currentUserId)
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    // MARK: - Send Friend Request
    private func sendFriendRequest(to user: UserFriend) async {
        guard let currentUser = Auth.auth().currentUser else { return }
        do {
            try await service.sendFriendRequest(
                from: currentUser.uid,
                fromName: currentUser.displayName ?? "Anonymous",
                fromEmail: currentUser.email ?? "",
                to: user.id
            )
            sentRequests.insert(user.id)
        } catch {
            errorMessage = "Failed to send friend request: \(error.localizedDescription)"
        }
    }
}

#Preview {
    FindFriendsView()
}
