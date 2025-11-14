
import SwiftUI
import FirebaseAuth

// MARK: - Alert Wrapper (Identifiable)
struct FindFriendsAlert: Identifiable {
    let id = UUID()
    let message: String
}

enum FriendTab {
    case allUsers
    case pendingRequests
    case friends
}

struct AllUsersView: View {
    @State private var allUsers: [UserFriend] = []
    @State private var pendingRequests: [UserFriend] = []
    @State private var friends: [UserFriend] = []
    @State private var sentRequests: Set<String> = []
    @State private var isLoading = true
    @State private var alertMessage: FindFriendsAlert?
    @State private var selectedTab: FriendTab = .allUsers

    private let friendService = FriendService()

    var body: some View {
        NavigationStack {
            VStack {
                Picker("Select Tab", selection: $selectedTab) {
                    Text("All Users").tag(FriendTab.allUsers)
                    Text("Pending Requests").tag(FriendTab.pendingRequests)
                    Text("Friends").tag(FriendTab.friends)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                ZStack {
                    if isLoading {
                        ProgressView("Loading…")
                    } else {
                        switch selectedTab {
                        case .allUsers:
                            List {
                                ForEach(allUsers) { user in
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(user.name)
                                                .font(.headline)
                                            Text(user.email)
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }

                                        Spacer()

                                        if sentRequests.contains(user.id) {
                                            Text("Requested")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        } else {
                                            Button("Add") {
                                                sendFriendRequest(to: user)
                                            }
                                            .buttonStyle(.bordered)
                                        }
                                    }
                                }
                            }
                        case .pendingRequests:
                            List {
                                ForEach(pendingRequests) { user in
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(user.name)
                                                .font(.headline)
                                            Text(user.email)
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }

                                        Spacer()

                                        HStack {
                                            Button("Accept") {
                                                acceptFriendRequest(from: user)
                                            }
                                            .buttonStyle(.borderedProminent)
                                            
                                            Button("Decline") {
                                                declineFriendRequest(from: user)
                                            }
                                            .buttonStyle(.bordered)
                                        }
                                    }
                                }
                            }
                        case .friends:
                            List {
                                ForEach(friends) { user in
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(user.name)
                                                .font(.headline)
                                            Text(user.email)
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }
                                        Spacer()
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("SIF Connect")
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
                case .allUsers:
                    allUsers = try await friendService.fetchAllUsers(excluding: currentUser.uid)
                    sentRequests = try await friendService.fetchSentRequests(for: currentUser.uid)
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
