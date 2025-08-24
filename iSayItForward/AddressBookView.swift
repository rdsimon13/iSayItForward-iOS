import SwiftUI

struct AddressBookView: View {
    @StateObject private var addressBookManager = AddressBookManager()
    @State private var searchText = ""
    @State private var selectedCategory: ContactCategory? = nil
    @State private var showingAddContact = false
    @State private var showingContactDetail: Contact? = nil
    @State private var showingDeleteAlert = false
    @State private var contactToDelete: Contact?
    
    // Filter contacts based on search and category
    private var filteredContacts: [Contact] {
        var contacts = addressBookManager.searchContacts(searchText)
        
        if let category = selectedCategory {
            contacts = contacts.filter { $0.category == category }
        }
        
        return contacts
    }
    
    var body: some View {
        ZStack {
            Color.mainAppGradient.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Search and Filter
                searchAndFilterView
                
                // Content
                if addressBookManager.isLoading {
                    loadingView
                } else if addressBookManager.contacts.isEmpty {
                    emptyStateView
                } else {
                    contactListView
                }
            }
        }
        .navigationTitle("Address Book")
        .navigationBarHidden(true)
        .sheet(isPresented: $showingAddContact) {
            AddContactView(addressBookManager: addressBookManager)
        }
        .sheet(item: $showingContactDetail) { contact in
            ContactDetailView(contact: contact, addressBookManager: addressBookManager)
        }
        .alert("Delete Contact", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let contact = contactToDelete {
                    Task {
                        try? await addressBookManager.deleteContact(contact)
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete \(contactToDelete?.displayName ?? "this contact")?")
        }
        .alert("Error", isPresented: .constant(addressBookManager.errorMessage != nil)) {
            Button("OK") {
                addressBookManager.errorMessage = nil
            }
        } message: {
            Text(addressBookManager.errorMessage ?? "")
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Text("Address Book")
                .font(.largeTitle.weight(.bold))
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: { showingAddContact = true }) {
                Image(systemName: "plus")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal)
        .padding(.top)
    }
    
    // MARK: - Search and Filter View
    private var searchAndFilterView: some View {
        VStack(spacing: 12) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search contacts...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
            
            // Category filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // All contacts filter
                    CategoryFilterButton(
                        title: "All",
                        iconName: "person.3.fill",
                        isSelected: selectedCategory == nil,
                        count: addressBookManager.contacts.count
                    ) {
                        selectedCategory = nil
                    }
                    
                    // Favorites filter
                    CategoryFilterButton(
                        title: "Favorites",
                        iconName: "heart.fill",
                        isSelected: false,
                        count: addressBookManager.favoriteContacts.count
                    ) {
                        // Show only favorites (we'll handle this in filtered contacts)
                    }
                    
                    // Category filters
                    ForEach(ContactCategory.allCases, id: \.self) { category in
                        CategoryFilterButton(
                            title: category.rawValue,
                            iconName: category.iconName,
                            isSelected: selectedCategory == category,
                            count: addressBookManager.contactsByCategory(category).count
                        ) {
                            selectedCategory = selectedCategory == category ? nil : category
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)
            Text("Loading contacts...")
                .foregroundColor(.white)
                .padding(.top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.7))
            
            Text("No Contacts Yet")
                .font(.title2.weight(.semibold))
                .foregroundColor(.white)
            
            Text("Tap the + button to add your first contact")
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            Button("Add Contact") {
                showingAddContact = true
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .padding(.top)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Contact List View
    private var contactListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Favorites section (if any and not filtering by category)
                if selectedCategory == nil && !addressBookManager.favoriteContacts.isEmpty {
                    favoritesSection
                }
                
                // Main contacts list
                ForEach(filteredContacts) { contact in
                    ContactRowView(contact: contact) {
                        showingContactDetail = contact
                    } onDelete: {
                        contactToDelete = contact
                        showingDeleteAlert = true
                    } onToggleFavorite: {
                        Task {
                            try? await addressBookManager.toggleFavorite(contact)
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 100) // Extra padding for tab bar
        }
    }
    
    // MARK: - Favorites Section
    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                Text("Favorites")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(addressBookManager.favoriteContacts.prefix(5)) { contact in
                        FavoriteContactCard(contact: contact) {
                            showingContactDetail = contact
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.bottom)
    }
}

// MARK: - Category Filter Button
private struct CategoryFilterButton: View {
    let title: String
    let iconName: String
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: iconName)
                    .font(.caption.weight(.semibold))
                Text(title)
                    .font(.caption.weight(.medium))
                if count > 0 {
                    Text("\(count)")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.brandDarkBlue.opacity(0.3))
                        .clipShape(Capsule())
                }
            }
            .foregroundColor(isSelected ? .white : Color.brandDarkBlue)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.brandDarkBlue : .white)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
        }
    }
}

// MARK: - Contact Row View
private struct ContactRowView: View {
    let contact: Contact
    let onTap: () -> Void
    let onDelete: () -> Void
    let onToggleFavorite: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color(hex: contact.category.color).opacity(0.2))
                Text(contact.displayName.prefix(1).uppercased())
                    .font(.headline.weight(.bold))
                    .foregroundColor(Color(hex: contact.category.color))
            }
            .frame(width: 50, height: 50)
            
            // Contact info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(contact.displayName)
                        .font(.headline)
                        .foregroundColor(Color.brandDarkBlue)
                    
                    if contact.isFavorite {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    Spacer()
                    
                    Image(systemName: contact.category.iconName)
                        .foregroundColor(Color(hex: contact.category.color))
                        .font(.caption)
                }
                
                if let email = contact.email, !email.isEmpty {
                    Text(email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if let phone = contact.phoneNumber, !phone.isEmpty {
                    Text(phone)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 3, y: 2)
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture {
            onTap()
        }
        .contextMenu {
            Button(action: onToggleFavorite) {
                Label(contact.isFavorite ? "Remove from Favorites" : "Add to Favorites", 
                      systemImage: contact.isFavorite ? "heart.slash" : "heart")
            }
            
            Button(action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Favorite Contact Card
private struct FavoriteContactCard: View {
    let contact: Contact
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.9))
                Text(contact.displayName.prefix(1).uppercased())
                    .font(.title2.weight(.bold))
                    .foregroundColor(Color(hex: contact.category.color))
            }
            .frame(width: 60, height: 60)
            
            Text(contact.displayName)
                .font(.caption.weight(.medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(width: 80)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture {
            onTap()
        }
    }
}

struct AddressBookView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AddressBookView()
        }
    }
}