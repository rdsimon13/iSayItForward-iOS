import SwiftUI

struct FriendPickerSheet: View {
    let deliveryType: DeliveryType
    @Binding var selected: [SIFRecipient]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("Friend Picker (stub)")
                    .font(.headline)
                Button("Add Demo Recipient") {
                    selected.append(SIFRecipient(name: "Demo", email: "demo@example.com"))
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("Select Friends")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { 
                        dismiss()
                    }
                }
            }
        }
    }
}
