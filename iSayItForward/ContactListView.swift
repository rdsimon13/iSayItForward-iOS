import SwiftUI

struct ContactListView: View {
    @StateObject private var contactManager = ContactManager()
    @State private var searchText = ""
    @State private var showingAddContact = false
    @State private var selectedContact: Contact?
    @State private var showingContactDetail = false
    @State private var showingSettings = false
    
    private var filteredContacts: [Contact] {
        contactManager.searchContacts(query: searchText)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if contactManager.isLoading {
                    ProgressView("Loading contacts...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredContacts.isEmpty && !searchText.isEmpty {
                    EmptySearchView(searchText: searchText)
                } else if contactManager.contacts.isEmpty {
                    EmptyContactsView()
                } else {
                    contactList
                }
            }
            .navigationTitle("Contacts")
            .searchable(text: $searchText, prompt: "Search contacts")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        showingAddContact = true
                    }
                }
            }
            .sheet(isPresented: $showingAddContact) {
                AddContactView(contactManager: contactManager)
            }
            .sheet(isPresented: $showingContactDetail) {
                if let contact = selectedContact {
                    ContactDetailView(contact: contact, contactManager: contactManager)
                }
            }
            .sheet(isPresented: $showingSettings) {
                ContactSettingsView(contactManager: contactManager)
            }
            .alert("Error", isPresented: .constant(contactManager.error != nil)) {
                Button("OK") {
                    contactManager.error = nil
                }
            } message: {
                Text(contactManager.error?.localizedDescription ?? "")
            }
        }
    }
    
    private var contactList: some View {
        List {
            ForEach(filteredContacts) { contact in
                ContactRowView(contact: contact)
                    .onTapGesture {
                        selectedContact = contact
                        showingContactDetail = true
                    }
                    .swipeActions(edge: .trailing) {
                        Button("Delete") {
                            contactManager.deleteContact(contact)
                        }
                        .tint(.red)
                        
                        Button(contact.isFavorite ? "Unfavorite" : "Favorite") {
                            contactManager.toggleContactFavorite(contact)
                        }
                        .tint(.yellow)
                        
                        Button(contact.isBlocked ? "Unblock" : "Block") {
                            contactManager.toggleContactBlocked(contact)
                        }
                        .tint(contact.isBlocked ? .green : .gray)
                    }
                    .swipeActions(edge: .leading) {
                        Button("SIF") {
                            // TODO: Navigate to send SIF with this contact
                            sendSIFToContact(contact)
                        }
                        .tint(.blue)
                    }
            }
        }
    }
    
    private func sendSIFToContact(_ contact: Contact) {
        // TODO: Integration with SIF sending functionality
        print("Sending SIF to \(contact.displayName)")
        contactManager.addContactActivity(for: contact.id, type: .sifSent, notes: "SIF sent from contact list")
    }
}

// MARK: - Contact Row View
struct ContactRowView: View {
    let contact: Contact
    
    var body: some View {
        HStack(spacing: 12) {
            ContactAvatarView(contact: contact, size: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(contact.displayName)
                        .font(.headline)
                        .foregroundColor(contact.isBlocked ? .secondary : .primary)
                    
                    Spacer()
                    
                    if contact.isFavorite {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                    
                    if contact.isBlocked {
                        Image(systemName: "slash.circle.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                if let email = contact.email {
                    Text(email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let phone = contact.phoneNumber {
                    Text(phone)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if !contact.tags.isEmpty {
                    HStack {
                        ForEach(contact.tags.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.blue.opacity(0.2))
                                .clipShape(Capsule())
                        }
                        
                        if contact.tags.count > 3 {
                            Text("+\(contact.tags.count - 3)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Spacer()
            
            VStack {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let lastContacted = contact.lastContactedDate {
                    Text(lastContacted, style: .relative)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Contact Avatar View
struct ContactAvatarView: View {
    let contact: Contact
    let size: CGFloat
    
    var body: some View {
        Group {
            if let avatarData = contact.avatarImageData,
               let uiImage = UIImage(data: avatarData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Text(contact.initials)
                    .font(.system(size: size * 0.4, weight: .medium))
                    .foregroundColor(.white)
                    .background(
                        Circle()
                            .fill(LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                    )
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

// MARK: - Empty States
struct EmptyContactsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 80))
                .foregroundColor(.secondary)
            
            Text("No Contacts Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Add your first contact to get started with organizing your connections.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EmptySearchView: View {
    let searchText: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 80))
                .foregroundColor(.secondary)
            
            Text("No Results")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("No contacts found for \"\(searchText)\"")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview
struct ContactListView_Previews: PreviewProvider {
    static var previews: some View {
        ContactListView()
    }
}