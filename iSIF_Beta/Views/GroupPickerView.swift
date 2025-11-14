import SwiftUI

struct GroupPickerView: View {
    @State private var groupName: String = ""
    @State private var groups: [String] = ["Group A", "Group B", "Group C"]
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Enter group name", text: $groupName)
                    .padding()
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: {
                    if !groupName.isEmpty {
                        groups.append(groupName)
                        groupName = ""
                    }
                }) {
                    Text("Create Group")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                List {
                    ForEach(groups, id: \.self) { group in
                        Text(group)
                    }
                }
            }
            .navigationTitle("Group Picker")
        }
    }
}

struct GroupPickerView_Previews: PreviewProvider {
    static var previews: some View {
        GroupPickerView()
    }
}