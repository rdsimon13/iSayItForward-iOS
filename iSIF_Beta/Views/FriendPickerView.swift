import SwiftUI

/// Friend picker that works with DeliveryType + SIFRecipient and mock FriendService.
/// No Firebase in the view; dependency is protocol-backed and injected.
struct FriendPickerView: View {
    @Environment(\.dismiss) private var dismiss

    // Dependencies
    private let friendsService: FriendsProviding

    // Inputs
    var deliveryType: DeliveryType
    @Binding var selectedFriends: [SIFRecipient]

    // Local state
    @State private var friends: [SIFRecipient] = []
    @State private var searchText: String = ""
    @State private var isLoading = true
    @State private var errorMessage: String?

    // MARK: - Init
    init(
        deliveryType: DeliveryType,
        selectedFriends: Binding<[SIFRecipient]>,
        friendsService: FriendsProviding = FriendService()
    ) {
        self.deliveryType = deliveryType
        self._selectedFriends = selectedFriends
        self.friendsService = friendsService
    }

    // MARK: - UI
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading friends…")
                        .padding(.top, 60)
                } else if let errorMessage {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text(errorMessage).font(.footnote)
                    }
                    .foregroundColor(.red)
                    .padding(.top, 60)
                } else {
                    List(filteredFriends) { friend in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(friend.name).font(.headline)
                                Text(friend.email).font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            if selectedFriends.contains(where: { $0.id == friend.id }) {
                                Image(systemName: "checkmark.circle.fill")
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { toggle(friend) }
                    }
                }
            }
            .navigationTitle("Select Friend" + (deliveryType == .oneToMany ? " (multi)" : ""))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .searchable(text: $searchText)
        .task { await loadFriends() }
    }

    private var filteredFriends: [SIFRecipient] {
        guard !searchText.isEmpty else { return friends }
        return friends.filter { f in
            f.name.localizedCaseInsensitiveContains(searchText) ||
            f.email.localizedCaseInsensitiveContains(searchText)
        }
    }

    private func toggle(_ friend: SIFRecipient) {
        if deliveryType == .oneToOne {
            selectedFriends = [friend]
            dismiss()
            return
        }
        // Multi-select
        if let idx = selectedFriends.firstIndex(where: { $0.id == friend.id }) {
            selectedFriends.remove(at: idx)
        } else {
            selectedFriends.append(friend)
        }
    }

    private func loadFriends() async {
        do {
            friends = try await friendsService.fetchFriends()
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}

#Preview {
    FriendPickerView(
        deliveryType: .oneToMany,
        selectedFriends: .constant([])
    )
    .environmentObject(AuthState())
    .environmentObject(TabRouter())
}
