
import SwiftUI
import FirebaseAuth

// MARK: - Alert Wrapper (Identifiable)
struct FindFriendsAlert: Identifiable {
    let id = UUID()
    let message: String
}

enum FriendTab {
    case search
    case pendingRequests
    case friends
}

struct AllUsersView: View {
    @EnvironmentObject var router: TabRouter
    @EnvironmentObject var authState: AuthState
    
    @State private var allUsers: [UserFriend] = []
    @State private var pendingRequests: [UserFriend] = []
    @State private var friends: [UserFriend] = []
    @State private var sentRequests: Set<String> = []
    @State private var isLoading = true
    @State private var alertMessage: FindFriendsAlert?
    @State private var selectedTab: FriendTab = .search
    @State private var searchText = ""
    @State private var isNavVisible = true

    private let friendService = FriendService()
    
    var filteredUsers: [UserFriend] {
        if searchText.isEmpty {
            return []
        }
        return allUsers.filter { user in
            user.name.localizedCaseInsensitiveContains(searchText) ||
            user.email.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(red: 0.0, green: 0.796, blue: 1.0), Color.white],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                Text("SIF Connect")
                    .font(.custom("AvenirNext-DemiBold", size: 24))
                    .foregroundColor(Color(hex: "132E37"))
                    .padding(.top, 20)
                
                // Tab Picker
                Picker("Select Tab", selection: $selectedTab) {
                    Text("Search").tag(FriendTab.search)
                    Text("Pending Requests").tag(FriendTab.pendingRequests)
                    Text("Friends").tag(FriendTab.friends)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Search Bar for Search Tab
                if selectedTab == .search {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search by name or email", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                
                // Content
                ZStack {
                    if isLoading {
                        ProgressView("Loading…")
                    } else {
                        switch selectedTab {
                        case .search:
                            if searchText.isEmpty {
                                Text("Search for users by name or email")
                                    .foregroundColor(.gray)
                                    .padding()
                            } else if filteredUsers.isEmpty {
                                Text("No users found for '\(searchText)'")
                                    .foregroundColor(.gray)
                                    .padding()
                            } else {
                                ScrollView {
                                    LazyVStack(spacing: 12) {
                                        ForEach(filteredUsers) { user in
                                            UserCardView(
                                                user: user,
                                                isFriend: friends.contains(where: { $0.id == user.id }),
                                                isRequested: sentRequests.contains(user.id),
                                                onAdd: { sendFriendRequest(to: user) },
                                                onViewProfile: { viewProfile(user) }
                                            )
                                        }
                                    }
                                    .padding()
                                }
                            }
                            
                        case .pendingRequests:
                            if pendingRequests.isEmpty {
                                Text("No pending requests")
                                    .foregroundColor(.gray)
                                    .padding()
                            } else {
                                ScrollView {
                                    LazyVStack(spacing: 12) {
                                        ForEach(pendingRequests) { user in
                                            PendingRequestCardView(
                                                user: user,
                                                onAccept: { acceptFriendRequest(from: user) },
                                                onDecline: { declineFriendRequest(from: user) }
                                            )
                                        }
                                    }
                                    .padding()
                                }
                            }
                            
                        case .friends:
                            if friends.isEmpty {
                                Text("No friends yet")
                                    .foregroundColor(.gray)
                                    .padding()
                            } else {
                                ScrollView {
                                    LazyVStack(spacing: 12) {
                                        ForEach(friends) { user in
                                            FriendCardView(user: user)
                                        }
                                    }
                                    .padding()
                                }
                            }
                        }
                    }
                }
                
                Spacer()
            }
            
            // Bottom Navigation
            VStack {
                Spacer()
                BottomNavBar(
                    selectedTab: $router.selectedTab,
                    isVisible: $isNavVisible
                )
                .environmentObject(router)
                .environmentObject(authState)
                .padding(.bottom, 8)
            }
        }
        .navigationBarHidden(true)
        .onAppear(perform: fetchData)
        .onChange(of: selectedTab) { _ in
            fetchData()
        }
        .alert(item: $alertMessage) { alert in
            Alert(
                title: Text("Friend Request"),
                message: Text(alert.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    // MARK: - Fetch data based on selected tab
    private func fetchData() {
        guard let currentUser = Auth.auth().currentUser else {
            alertMessage = FindFriendsAlert(message: "You must be logged in.")
            return
        }

        isLoading = true
        Task {
            do {
                switch selectedTab {
                case .search:
                    allUsers = try await friendService.fetchAllUsers(excluding: currentUser.uid)
                    sentRequests = try await friendService.fetchSentRequests(for: currentUser.uid)
                    friends = try await friendService.fetchFriends(for: currentUser.uid)
                case .pendingRequests:
                    pendingRequests = try await friendService.fetchReceivedRequests(for: currentUser.uid)
                case .friends:
                    friends = try await friendService.fetchFriends(for: currentUser.uid)
                }
                isLoading = false
            } catch {
                isLoading = false
                alertMessage = FindFriendsAlert(message: "Failed to load data: \(error.localizedDescription)")
            }
        }
    }

    private func viewProfile(_ user: UserFriend) {
        // Navigate to user profile
        print("View profile for \(user.name)")
    }

    // MARK: - Send Friend Request
    private func sendFriendRequest(to user: UserFriend) {
        guard let currentUser = Auth.auth().currentUser else {
            alertMessage = FindFriendsAlert(message: "You must be logged in.")
            return
        }

        Task {
            do {
                let name = currentUser.displayName ?? "Anonymous"
                let email = currentUser.email ?? "noemail@example.com"

                try await friendService.sendFriendRequest(
                    from: currentUser.uid,
                    fromName: name,
                    fromEmail: email,
                    to: user.id,
                    toName: user.name,
                    toEmail: user.email
                )

                sentRequests.insert(user.id)
                alertMessage = FindFriendsAlert(message: "Friend request sent to \(user.name).")

            } catch {
                alertMessage = FindFriendsAlert(message: "Error sending request: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Accept Friend Request
    private func acceptFriendRequest(from user: UserFriend) {
        guard let currentUser = Auth.auth().currentUser else {
            alertMessage = FindFriendsAlert(message: "You must be logged in.")
            return
        }

        Task {
            do {
                try await friendService.acceptFriendRequest(from: user.id, to: currentUser.uid)
                // Remove from pending requests and refresh friends
                if let index = pendingRequests.firstIndex(where: { $0.id == user.id }) {
                    pendingRequests.remove(at: index)
                }
                alertMessage = FindFriendsAlert(message: "Accepted friend request from \(user.name).")
                // Refresh friends list
                if selectedTab == .friends {
                    friends = try await friendService.fetchFriends(for: currentUser.uid)
                }
            } catch {
                alertMessage = FindFriendsAlert(message: "Error accepting request: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Decline Friend Request
    private func declineFriendRequest(from user: UserFriend) {
        guard let currentUser = Auth.auth().currentUser else {
            alertMessage = FindFriendsAlert(message: "You must be logged in.")
            return
        }

        Task {
            do {
                try await friendService.declineFriendRequest(from: user.id, to: currentUser.uid)
                if let index = pendingRequests.firstIndex(where: { $0.id == user.id }) {
                    pendingRequests.remove(at: index)
                }
                alertMessage = FindFriendsAlert(message: "Declined friend request from \(user.name).")
            } catch {
                alertMessage = FindFriendsAlert(message: "Error declining request: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - User Card View
struct UserCardView: View {
    let user: UserFriend
    let isFriend: Bool
    let isRequested: Bool
    let onAdd: () -> Void
    let onViewProfile: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 50, height: 50)
                .foregroundColor(.gray)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.name)
                    .font(.headline)
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            if isFriend {
                Button("Profile") {
                    onViewProfile()
                }
                .buttonStyle(.bordered)
                .tint(.blue)
            } else if isRequested {
                Text("Requested")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
            } else {
                Button(action: onAdd) {
                    Text("Add")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "003366"), Color(hex: "00AEEF")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.9))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }
}

// MARK: - Pending Request Card View
struct PendingRequestCardView: View {
    let user: UserFriend
    let onAccept: () -> Void
    let onDecline: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 50, height: 50)
                .foregroundColor(.gray)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.name)
                    .font(.headline)
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text("Friend Request")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            
            Spacer()
            
            HStack {
                Button("Accept") {
                    onAccept()
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                
                Button("Decline") {
                    onDecline()
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
        }
        .padding()
        .background(Color.white.opacity(0.9))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }
}

// MARK: - Friend Card View
struct FriendCardView: View {
    let user: UserFriend
    
    var body: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 50, height: 50)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.name)
                    .font(.headline)
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text("Friend")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            
            Spacer()
            
            Button("Message") {
                // Start chat with friend
            }
            .buttonStyle(.bordered)
            .tint(.blue)
        }
        .padding()
        .background(Color.white.opacity(0.9))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }
}
