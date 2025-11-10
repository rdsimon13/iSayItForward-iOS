import SwiftUI
import FirebaseAuth

// MARK: - Identifiable Alert Wrapper
struct AlertMessage: Identifiable {
    let id = UUID()
    let message: String
}

struct FindFriendsView: View {
    @State private var allUsers: [UserFriend] = []
    @State private var sentRequests: Set<String> = []
    @State private var errorMessage: AlertMessage?

    private let service = FriendService()

    var body: some View {
        NavigationStack {
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
                                Task {
                                    await sendFriendRequest(to: user)
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }
            .navigationTitle("Find Friends")
            .onAppear(perform: fetchUsers)
            .alert(item: $errorMessage) { message in
                Alert(title: Text("Error"), message: Text(message.message), dismissButton: .default(Text("OK")))
            }
        }
    }

    private func fetchUsers() {
        guard let currentUser = Auth.auth().currentUser else {
            errorMessage = AlertMessage(message: "You must be logged in.")
            return
        }

        Task {
            do {
                allUsers = try await service.fetchAllUsers(excluding: currentUser.uid)
                sentRequests = try await service.fetchSentRequests(for: currentUser.uid)
            } catch {
                errorMessage = AlertMessage(message: "Failed to load users: \(error.localizedDescription)")
            }
        }
    }

    private func sendFriendRequest(to user: UserFriend) async {
        guard let currentUser = Auth.auth().currentUser else {
            errorMessage = AlertMessage(message: "You must be logged in.")
            return
        }

        do {
            try await service.sendFriendRequest(
                from: currentUser.uid,
                fromName: currentUser.displayName ?? "Anonymous",
                fromEmail: currentUser.email ?? "",
                to: user.id,
                toName: user.name,
                toEmail: user.email
            )

            sentRequests.insert(user.id)
        } catch {
            errorMessage = AlertMessage(message: "Failed to send friend request: \(error.localizedDescription)")
        }
    }
}

#Preview {
    FindFriendsView()
}
