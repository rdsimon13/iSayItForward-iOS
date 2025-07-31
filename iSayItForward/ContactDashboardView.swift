import SwiftUI

// MARK: - Contact Management Dashboard
struct ContactDashboardView: View {
    @StateObject private var contactManager = ContactManager()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ContactListView()
                .environmentObject(contactManager)
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Contacts")
                }
                .tag(0)
            
            ContactGroupsView(contactManager: contactManager)
                .tabItem {
                    Image(systemName: "folder.fill")
                    Text("Groups")
                }
                .tag(1)
            
            ContactAnalyticsView(contactManager: contactManager)
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Analytics")
                }
                .tag(2)
            
            ContactSettingsView(contactManager: contactManager)
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(3)
        }
    }
}

// MARK: - Contact Groups Management View
struct ContactGroupsView: View {
    @ObservedObject var contactManager: ContactManager
    @State private var showingAddGroup = false
    @State private var showingGroupDetail = false
    @State private var selectedGroup: ContactGroup?
    
    var body: some View {
        NavigationView {
            List {
                Section("System Groups") {
                    ForEach(ContactGroup.allSystemGroups) { group in
                        ContactGroupRowView(
                            group: group,
                            contactCount: contactManager.getContactsByGroup(group).count
                        ) {
                            selectedGroup = group
                            showingGroupDetail = true
                        }
                    }
                }
                
                Section("Custom Groups") {
                    ForEach(contactManager.contactGroups.filter { !$0.isSystemGroup }) { group in
                        ContactGroupRowView(
                            group: group,
                            contactCount: 0 // TODO: Implement custom group contact counting
                        ) {
                            selectedGroup = group
                            showingGroupDetail = true
                        }
                    }
                    .onDelete(perform: deleteGroups)
                }
            }
            .navigationTitle("Contact Groups")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Group") {
                        showingAddGroup = true
                    }
                }
            }
            .sheet(isPresented: $showingAddGroup) {
                AddContactGroupView(contactManager: contactManager)
            }
            .sheet(isPresented: $showingGroupDetail) {
                if let group = selectedGroup {
                    ContactGroupDetailView(group: group, contactManager: contactManager)
                }
            }
        }
    }
    
    private func deleteGroups(offsets: IndexSet) {
        let customGroups = contactManager.contactGroups.filter { !$0.isSystemGroup }
        for index in offsets {
            let group = customGroups[index]
            contactManager.deleteContactGroup(group)
        }
    }
}

// MARK: - Contact Group Row View
struct ContactGroupRowView: View {
    let group: ContactGroup
    let contactCount: Int
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: group.colorHex) ?? .blue)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: iconForGroup(group))
                        .foregroundColor(.white)
                        .font(.headline)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(group.name)
                    .font(.headline)
                
                Text("\(contactCount) contacts")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if group.isSystemGroup {
                Text("System")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color(.systemGray5))
                    .clipShape(Capsule())
            }
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
    
    private func iconForGroup(_ group: ContactGroup) -> String {
        switch group.name {
        case "Favorites": return "heart.fill"
        case "Recent": return "clock.fill"
        case "Blocked": return "slash.circle.fill"
        default: return "folder.fill"
        }
    }
}

// MARK: - Add Contact Group View
struct AddContactGroupView: View {
    @ObservedObject var contactManager: ContactManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var groupName = ""
    @State private var selectedColor = "#007AFF"
    @State private var showingColorPicker = false
    
    private let availableColors = [
        "#007AFF", "#FF3B30", "#FF9500", "#FFCC00",
        "#34C759", "#00C7BE", "#30B0C7", "#5856D6",
        "#AF52DE", "#FF2D92", "#A2845E", "#8E8E93"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Group Information") {
                    TextField("Group Name", text: $groupName)
                    
                    HStack {
                        Text("Color")
                        Spacer()
                        Button(action: {
                            showingColorPicker.toggle()
                        }) {
                            Circle()
                                .fill(Color(hex: selectedColor) ?? .blue)
                                .frame(width: 30, height: 30)
                        }
                    }
                    
                    if showingColorPicker {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                            ForEach(availableColors, id: \.self) { color in
                                Button(action: {
                                    selectedColor = color
                                    showingColorPicker = false
                                }) {
                                    Circle()
                                        .fill(Color(hex: color) ?? .blue)
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Circle()
                                                .stroke(selectedColor == color ? Color.primary : Color.clear, lineWidth: 2)
                                        )
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("New Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveGroup()
                    }
                    .disabled(groupName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
    
    private func saveGroup() {
        let group = ContactGroup(
            name: groupName.trimmingCharacters(in: .whitespaces),
            colorHex: selectedColor
        )
        contactManager.addContactGroup(group)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Contact Group Detail View
struct ContactGroupDetailView: View {
    let group: ContactGroup
    @ObservedObject var contactManager: ContactManager
    @Environment(\.presentationMode) var presentationMode
    
    private var groupContacts: [Contact] {
        contactManager.getContactsByGroup(group)
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Circle()
                            .fill(Color(hex: group.colorHex) ?? .blue)
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: iconForGroup(group))
                                    .foregroundColor(.white)
                                    .font(.title2)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(group.name)
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("\(groupContacts.count) contacts")
                                .font(.body)
                                .foregroundColor(.secondary)
                            
                            if group.isSystemGroup {
                                Text("System Group")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color(.systemGray5))
                                    .clipShape(Capsule())
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                
                if groupContacts.isEmpty {
                    Section {
                        Text("No contacts in this group")
                            .foregroundColor(.secondary)
                            .padding()
                    }
                } else {
                    Section("Contacts") {
                        ForEach(groupContacts) { contact in
                            ContactRowView(contact: contact)
                        }
                    }
                }
            }
            .navigationTitle(group.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private func iconForGroup(_ group: ContactGroup) -> String {
        switch group.name {
        case "Favorites": return "heart.fill"
        case "Recent": return "clock.fill"
        case "Blocked": return "slash.circle.fill"
        default: return "folder.fill"
        }
    }
}

// MARK: - Contact Analytics View
struct ContactAnalyticsView: View {
    @ObservedObject var contactManager: ContactManager
    
    private var analytics: ContactAnalytics {
        ContactAnalytics(contacts: contactManager.contacts)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    overviewSection
                    chartsSection
                    insightsSection
                }
                .padding()
            }
            .navigationTitle("Contact Analytics")
        }
    }
    
    private var overviewSection: some View {
        VStack(spacing: 16) {
            Text("Contact Overview")
                .font(.title2)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                AnalyticsCard(
                    title: "Total Contacts",
                    value: "\(analytics.totalContacts)",
                    icon: "person.2.fill",
                    color: .blue
                )
                
                AnalyticsCard(
                    title: "Favorites",
                    value: "\(analytics.favoriteContacts)",
                    icon: "heart.fill",
                    color: .red
                )
                
                AnalyticsCard(
                    title: "Blocked",
                    value: "\(analytics.blockedContacts)",
                    icon: "slash.circle.fill",
                    color: .gray
                )
                
                AnalyticsCard(
                    title: "Groups",
                    value: "\(analytics.totalGroups)",
                    icon: "folder.fill",
                    color: .orange
                )
            }
        }
    }
    
    private var chartsSection: some View {
        VStack(spacing: 16) {
            Text("Privacy Distribution")
                .font(.title2)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 20) {
                ForEach(ContactPrivacyLevel.allCases, id: \.self) { level in
                    VStack {
                        Text("\(analytics.contactsByPrivacyLevel[level] ?? 0)")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(level.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
    
    private var insightsSection: some View {
        VStack(spacing: 12) {
            Text("Insights")
                .font(.title2)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 8) {
                ForEach(analytics.insights, id: \.self) { insight in
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                        
                        Text(insight)
                            .font(.body)
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }
}

// MARK: - Analytics Card
struct AnalyticsCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Contact Analytics Model
struct ContactAnalytics {
    let contacts: [Contact]
    
    var totalContacts: Int {
        contacts.count
    }
    
    var favoriteContacts: Int {
        contacts.filter { $0.isFavorite }.count
    }
    
    var blockedContacts: Int {
        contacts.filter { $0.isBlocked }.count
    }
    
    var totalGroups: Int {
        ContactGroup.allSystemGroups.count // + custom groups when implemented
    }
    
    var contactsByPrivacyLevel: [ContactPrivacyLevel: Int] {
        var distribution: [ContactPrivacyLevel: Int] = [:]
        for level in ContactPrivacyLevel.allCases {
            distribution[level] = contacts.filter { $0.privacyLevel == level }.count
        }
        return distribution
    }
    
    var insights: [String] {
        var insights: [String] = []
        
        if favoriteContacts == 0 {
            insights.append("Consider marking frequently contacted people as favorites for quick access")
        }
        
        if blockedContacts > 0 {
            insights.append("You have \(blockedContacts) blocked contact(s)")
        }
        
        let contactsWithoutEmail = contacts.filter { $0.email == nil }.count
        if contactsWithoutEmail > 0 {
            insights.append("\(contactsWithoutEmail) contacts are missing email addresses")
        }
        
        let contactsWithoutPhone = contacts.filter { $0.phoneNumber == nil }.count
        if contactsWithoutPhone > 0 {
            insights.append("\(contactsWithoutPhone) contacts are missing phone numbers")
        }
        
        if totalContacts > 0 {
            let privacyDistribution = contactsByPrivacyLevel
            let privateCount = privacyDistribution[.private_] ?? 0
            if privateCount > totalContacts / 2 {
                insights.append("Most of your contacts have high privacy settings")
            }
        }
        
        return insights
    }
}

// MARK: - Color Extension
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview
struct ContactDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        ContactDashboardView()
    }
}