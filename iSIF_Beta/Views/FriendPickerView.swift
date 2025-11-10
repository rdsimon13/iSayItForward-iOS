import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct FriendPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var friendService = FriendService()
    @Binding var selectedFriends: [UserFriend]
    var deliveryType: String

    @State private var friends: [UserFriend] = []
    @State private var searchText = ""
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack {
                searchBar
                if isLoading {
                    ProgressView("Loading friends...")
                        .font(.custom("AvenirNext-Regular", size: 15))
                        .padding(.top, 60)
                } else if let error = errorMessage {
                    Text("⚠️ \(error)")
                        .foregroundColor(.red)
                        .padding(.top, 60)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredFriends) { friend in
                                friendRow(friend)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                }
            }
            .navigationTitle("Select Friend\(deliveryType == "One-to-Many" ? "s" : "")")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .disabled(selectedFriends.isEmpty)
                }
            }
            .task { await loadFriends() }
        }
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundColor(.gray)
            TextField("Search friends...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.custom("AvenirNext-Regular", size: 15))
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.9)))
        .padding(.horizontal)
    }

    private var filteredFriends: [UserFriend] {
        if searchText.isEmpty { return friends }
        return friends.filter { friend in
            friend.name.localizedCaseInsensitiveContains(searchText) ||
            friend.email.localizedCaseInsensitiveContains(searchText)
        }
    }

    private func friendRow(_ friend: UserFriend) -> some View {
        let isSelected = selectedFriends.contains(friend)
        return Button {
            if deliveryType == "One-to-One" {
                selectedFriends = [friend]
            } else {
                if isSelected {
                    selectedFriends.removeAll { $0.id == friend.id }
                } else {
                    selectedFriends.append(friend)
                }
            }
        } label: {
            HStack {
                Circle()
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 50, height: 50)
                    .overlay(Text(friend.name.prefix(1)).foregroundColor(.white))
                VStack(alignment: .leading) {
                    Text(friend.name).font(.custom("AvenirNext-Medium", size: 16))
                    Text(friend.email).font(.custom("AvenirNext-Regular", size: 13)).foregroundColor(.gray)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                }
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.9)))
        }
    }

    private func loadFriends() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not logged in."
            isLoading = false
            return
        }

        do {
            friends = try await friendService.fetchFriends(for: userId)
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}
#Preview {
    FriendPickerView(
        selectedFriends: .constant([]),
        deliveryType: "One-to-Many"
    )
}
