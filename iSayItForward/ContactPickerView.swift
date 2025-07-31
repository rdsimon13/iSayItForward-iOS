import SwiftUI

// MARK: - Contact Picker View
struct ContactPickerView: View {
    @ObservedObject var contactManager: ContactManager
    @Binding var selectedContacts: [Contact]
    @Environment(\.presentationMode) var presentationMode
    
    @State private var searchText = ""
    @State private var selectedGroup: ContactGroup?
    @State private var showFavoritesOnly = false
    
    private var filteredContacts: [Contact] {
        var contacts = contactManager.contacts.filter { !$0.isBlocked }
        
        if showFavoritesOnly {
            contacts = contacts.filter { $0.isFavorite }
        }
        
        if let group = selectedGroup {
            contacts = contactManager.getContactsByGroup(group)
        }
        
        if !searchText.isEmpty {
            contacts = contacts.filter { contact in
                contact.fullName.localizedCaseInsensitiveContains(searchText) ||
                contact.email?.localizedCaseInsensitiveContains(searchText) == true ||
                contact.phoneNumber?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        return contacts.sorted { $0.displayName < $1.displayName }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                searchAndFilterSection
                
                if filteredContacts.isEmpty {
                    EmptyContactPickerView(searchText: searchText)
                } else {
                    contactList
                }
                
                if !selectedContacts.isEmpty {
                    selectedContactsSection
                }
            }
            .navigationTitle("Select Contacts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(selectedContacts.isEmpty)
                }
            }
        }
    }
    
    private var searchAndFilterSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search contacts", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    FilterChip(
                        title: "All",
                        isSelected: selectedGroup == nil && !showFavoritesOnly
                    ) {
                        selectedGroup = nil
                        showFavoritesOnly = false
                    }
                    
                    FilterChip(
                        title: "Favorites",
                        isSelected: showFavoritesOnly
                    ) {
                        showFavoritesOnly.toggle()
                        selectedGroup = nil
                    }
                    
                    ForEach(ContactGroup.allSystemGroups.filter { $0.name != "Blocked" }) { group in
                        FilterChip(
                            title: group.name,
                            isSelected: selectedGroup?.id == group.id
                        ) {
                            if selectedGroup?.id == group.id {
                                selectedGroup = nil
                            } else {
                                selectedGroup = group
                                showFavoritesOnly = false
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
    }
    
    private var contactList: some View {
        List {
            ForEach(filteredContacts) { contact in
                ContactPickerRowView(
                    contact: contact,
                    isSelected: selectedContacts.contains { $0.id == contact.id }
                ) {
                    toggleContactSelection(contact)
                }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private var selectedContactsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Selected (\(selectedContacts.count))")
                    .font(.headline)
                
                Spacer()
                
                Button("Clear All") {
                    selectedContacts.removeAll()
                }
                .font(.caption)
                .foregroundColor(.red)
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(selectedContacts) { contact in
                        SelectedContactChip(contact: contact) {
                            selectedContacts.removeAll { $0.id == contact.id }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
    
    private func toggleContactSelection(_ contact: Contact) {
        if selectedContacts.contains(where: { $0.id == contact.id }) {
            selectedContacts.removeAll { $0.id == contact.id }
        } else {
            selectedContacts.append(contact)
        }
    }
}

// MARK: - Contact Picker Row View
struct ContactPickerRowView: View {
    let contact: Contact
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            ContactAvatarView(contact: contact, size: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(contact.displayName)
                    .font(.body)
                
                if let email = contact.email {
                    Text(email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if let phone = contact.phoneNumber {
                    Text(phone)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if contact.isFavorite {
                Image(systemName: "heart.fill")
                    .foregroundColor(.yellow)
                    .font(.caption)
            }
            
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .blue : .secondary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

// MARK: - Selected Contact Chip
struct SelectedContactChip: View {
    let contact: Contact
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            ContactAvatarView(contact: contact, size: 24)
            
            Text(contact.firstName)
                .font(.caption)
                .lineLimit(1)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray5))
        .clipShape(Capsule())
    }
}

// MARK: - Empty Contact Picker View
struct EmptyContactPickerView: View {
    let searchText: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Contacts Found")
                .font(.title2)
                .fontWeight(.semibold)
            
            if !searchText.isEmpty {
                Text("No contacts match \"\(searchText)\"")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("Add some contacts to get started")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - SIF Contact Integration Helper
struct SIFContactHelper {
    static func createSIFWithContacts(_ contacts: [Contact], subject: String, message: String, scheduledDate: Date = Date()) -> SIFItem {
        let recipients = contacts.compactMap { contact in
            contact.email ?? contact.phoneNumber
        }
        
        let authorUid = Auth.auth().currentUser?.uid ?? "demo"
        
        return SIFItem(
            authorUid: authorUid,
            recipients: recipients,
            subject: subject,
            message: message,
            createdDate: Date(),
            scheduledDate: scheduledDate
        )
    }
    
    static func recordSIFSentActivity(to contacts: [Contact], sifId: String, contactManager: ContactManager) {
        for contact in contacts {
            contactManager.addContactActivity(
                for: contact.id,
                type: .sifSent,
                sifId: sifId,
                notes: "SIF sent: \(sifId.prefix(8))"
            )
        }
    }
}

// MARK: - Preview
struct ContactPickerView_Previews: PreviewProvider {
    static var previews: some View {
        ContactPickerView(
            contactManager: ContactManager(),
            selectedContacts: .constant([])
        )
    }
}