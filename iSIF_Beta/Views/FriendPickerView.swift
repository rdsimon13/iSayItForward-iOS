// FriendPickerView.swift

import SwiftUI

struct FriendPickerView: View {
    let deliveryType: DeliveryType
    @Binding var selectedFriends: [SIFRecipient]
    @Environment(\.dismiss) private var dismiss
    
    // Mock data for friends
    private let mockFriends = [
        SIFRecipient(name: "John Doe", email: "john@example.com"),
        SIFRecipient(name: "Jane Roe", email: "jane@example.com"),
        SIFRecipient(name: "Alex Smith", email: "alex@example.com")
    ]
    
    var body: some View {
        NavigationView {
            List(mockFriends, id: \.id) { friend in
                Button(action: {
                    selectFriend(friend)
                }) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(friend.name)
                                .font(.headline)
                            Text(friend.email)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        if selectedFriends.contains(where: { $0.id == friend.id }) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .foregroundColor(.primary)
            }
            .navigationTitle(deliveryType == .oneToMany ? "Pick Recipients" : "Pick Recipient")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func selectFriend(_ friend: SIFRecipient) {
        if deliveryType == .oneToOne {
            selectedFriends = [friend]
            dismiss()
        } else {
            if let index = selectedFriends.firstIndex(where: { $0.id == friend.id }) {
                selectedFriends.remove(at: index)
            } else {
                selectedFriends.append(friend)
            }
        }
    }
}
