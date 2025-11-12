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
                } else if let errorMessage {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text(errorMessage).font(.footnote)
                    }
                    .foregroundColor(.red)
                } else {
                    List(filteredFriends) { friend in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(friend.name).font(.headline)
                                Text(friend.email).font(.caption).foregroundColor(.gray)
                            }
                            Spacer()
                            if isSelected(friend) {
                                Image(systemName: "checkmark.circle.fill")
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { toggle(friend) }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Select Friend\(deliveryType == .oneToOne ? "" : "s")")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .disabled(deliveryType != .oneToOne && selectedFriends.isEmpty)
                }
            }
            .searchable(text: $searchText)
        }
        .task { await loadFriends() }
    }

    // MARK: - Helpers
    private var filteredFriends: [SIFRecipient] {
        guard !searchText.isEmpty else { return friends }
        let q = searchText.lowercased()
        return friends.filter { $0.name.lowercased().contains(q) || $0.email.lowercased().contains(q) }
    }

    private func loadFriends() async {
        isLoading = true
        defer { isLoading = false }
        do {
            friends = try await friendsService.fetchFriends()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func isSelected(_ f: SIFRecipient) -> Bool {
        selectedFriends.contains(where: { $0.id == f.id })
    }

    private func toggle(_ f: SIFRecipient) {
        switch deliveryType {
        case .oneToOne:
            selectedFriends = [f]
        case .oneToMany, .group:
            if let idx = selectedFriends.firstIndex(where: { $0.id == f.id }) {
                selectedFriends.remove(at: idx)
            } else {
                selectedFriends.append(f)
            }
        }
    }
}

#Preview {
    FriendPickerView(
        deliveryType: .oneToMany,
        selectedFriends: .constant([])
    )
}
