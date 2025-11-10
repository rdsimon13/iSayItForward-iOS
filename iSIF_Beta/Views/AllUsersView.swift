
import SwiftUI
import FirebaseAuth

// MARK: - Alert Wrapper (Identifiable)
struct FindFriendsAlert: Identifiable {
    let id = UUID()
    let message: String
}

struct AllUsersView: View {
    @State private var allUsers: [UserFriend] = []
    @State private var sentRequests: Set<String> = []
    @State private var isLoading = true
    @State private var alertMessage: FindFriendsAlert?

    private let friendService = FriendService()

    var body: some View {
        NavigationStack {
            ZStack {
                if isLoading {
                    ProgressView("Loading users…")
                } else {
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
                }
            }
            .navigationTitle("Add Friends")
            .onAppear(perform: fetchUsers)
            .alert(item: $alertMessage) { alert in
                Alert(
                    title: Text("Friend Request"),
                    message: Text(alert.message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    // MARK: - Fetch all users and sent requests
    private func fetchUsers() {
        guard let currentUser = Auth.auth().currentUser else {
            alertMessage = FindFriendsAlert(message: "You must be logged in.")
            return
        }

        Task {
            do {
                allUsers = try await friendService.fetchAllUsers(excluding: currentUser.uid)
                sentRequests = try await friendService.fetchSentRequests(for: currentUser.uid)
                isLoading = false
            } catch {
                isLoading = false
                alertMessage = FindFriendsAlert(message: "Failed to load users: \(error.localizedDescription)")
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
}
