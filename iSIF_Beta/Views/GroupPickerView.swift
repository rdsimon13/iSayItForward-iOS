import SwiftUI

struct GroupPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var router: TabRouter
    @EnvironmentObject var authState: AuthState
    @Binding var selectedFriends: [SIFRecipient]
    
    // Sample groups - in a real app, these would come from a service
    private let sampleGroups: [GroupModel] = [
        GroupModel(
            name: "Family",
            members: [
                SIFRecipient(id: "1", name: "John Doe", email: "john@example.com"),
                SIFRecipient(id: "2", name: "Jane Doe", email: "jane@example.com")
            ]
        ),
        GroupModel(
            name: "Friends", 
            members: [
                SIFRecipient(id: "3", name: "Alice Smith", email: "alice@example.com"),
                SIFRecipient(id: "4", name: "Bob Johnson", email: "bob@example.com")
            ]
        )
    ]
    
    var body: some View {
        NavigationView {
            List(sampleGroups) { group in
                Button(action: {
                    selectedFriends = group.members
                    dismiss()
                }) {
                    VStack(alignment: .leading) {
                        Text(group.name)
                            .font(.headline)
                        Text("\(group.members.count) members")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Select Group")
            .navigationBarItems(trailing: Button("Cancel") { dismiss() })
        }
    }
}

struct GroupModel: Identifiable {
    let id = UUID().uuidString
    let name: String
    let members: [SIFRecipient]
}

struct GroupPickerView_Previews: PreviewProvider {
    static var previews: some View {
        GroupPickerView(selectedFriends: .constant([]))
    }
}
