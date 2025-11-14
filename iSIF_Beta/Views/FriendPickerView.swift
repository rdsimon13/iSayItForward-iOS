// FriendPickerView.swift

import SwiftUI

struct FriendPickerView: View {
    let deliveryType: DeliveryType
    @Binding var selectedFriends: [SIFRecipient]
    @Environment(\.dismiss) private var dismiss
    @State private var showGroupPicker = false
    
    // Mock data for friends
    private let mockFriends = [
        SIFRecipient(name: "John Doe", email: "john@example.com"),
        SIFRecipient(name: "Jane Roe", email: "jane@example.com"),
        SIFRecipient(name: "Alex Smith", email: "alex@example.com")
    ]
    
    var body: some View {
        NavigationView {
            VStack {
                if deliveryType == .toGroup {
                    Button("Select Group") {
                        showGroupPicker = true
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding()
                }
                
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
            }
            .navigationTitle(deliveryType == .oneToMany ? "Pick Recipients" : 
                            deliveryType == .toGroup ? "Pick Group or Friends" : "Pick Recipient")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showGroupPicker) {
                GroupPickerView(selectedFriends: $selectedFriends)
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

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}
