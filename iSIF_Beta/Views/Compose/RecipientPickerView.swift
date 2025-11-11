import SwiftUI

struct RecipientPickerView: View {
    @Environment(\.dismiss) var dismiss
    let friendsProvider: FriendsProviding
    let deliveryType: DeliveryType
    @Binding var selectedRecipients: [SIFRecipient]
    
    @State private var friends: [SIFRecipient] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                BrandTheme.backgroundGradient.ignoresSafeArea()
                
                if isLoading {
                    ProgressView("Loading friends...")
                } else if let errorMessage = errorMessage {
                    Text("Error: \(errorMessage)")
                        .foregroundColor(.red)
                } else {
                    List {
                        ForEach(friends) { friend in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(friend.name)
                                        .font(.headline)
                                    Text(friend.email)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                if selectedRecipients.contains(where: { $0.id == friend.id }) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                toggleSelection(for: friend)
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Select Recipients")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadFriends()
            }
        }
    }
    
    private func toggleSelection(for friend: SIFRecipient) {
        if deliveryType == .oneToOne {
            selectedRecipients = [friend]
        } else {
            if let index = selectedRecipients.firstIndex(where: { $0.id == friend.id }) {
                selectedRecipients.remove(at: index)
            } else {
                selectedRecipients.append(friend)
            }
        }
    }
    
    private func loadFriends() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            friends = try await friendsProvider.fetchFriends()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
