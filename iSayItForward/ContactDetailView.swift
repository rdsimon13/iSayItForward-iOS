import SwiftUI

struct ContactDetailView: View {
    @State var contact: Contact
    @ObservedObject var contactManager: ContactManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var isEditing = false
    @State private var showingDeleteAlert = false
    @State private var activities: [ContactActivity] = []
    @State private var showingActivityDetail = false
    @State private var selectedActivity: ContactActivity?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    
                    if isEditing {
                        editingSection
                    } else {
                        detailSections
                    }
                    
                    activitySection
                }
                .padding()
            }
            .navigationTitle(isEditing ? "Edit Contact" : contact.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(isEditing ? "Cancel" : "Done") {
                        if isEditing {
                            isEditing = false
                        } else {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        if !isEditing {
                            Menu {
                                Button(action: sendSIF) {
                                    Label("Send SIF", systemImage: "envelope")
                                }
                                
                                Button(action: toggleFavorite) {
                                    Label(contact.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                                          systemImage: contact.isFavorite ? "heart.slash" : "heart")
                                }
                                
                                Button(action: toggleBlocked) {
                                    Label(contact.isBlocked ? "Unblock" : "Block",
                                          systemImage: contact.isBlocked ? "person.crop.circle.badge.plus" : "person.crop.circle.badge.minus")
                                }
                                .foregroundColor(contact.isBlocked ? .green : .red)
                                
                                Divider()
                                
                                Button(action: { showingDeleteAlert = true }) {
                                    Label("Delete Contact", systemImage: "trash")
                                }
                                .foregroundColor(.red)
                            } label: {
                                Image(systemName: "ellipsis.circle")
                            }
                        }
                        
                        Button(isEditing ? "Save" : "Edit") {
                            if isEditing {
                                saveChanges()
                            } else {
                                isEditing = true
                            }
                        }
                    }
                }
            }
            .alert("Delete Contact", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) {
                    deleteContact()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete \(contact.displayName)? This action cannot be undone.")
            }
            .onAppear {
                loadActivities()
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            ContactAvatarView(contact: contact, size: 120)
            
            VStack(spacing: 4) {
                Text(contact.displayName)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                HStack(spacing: 12) {
                    if contact.isFavorite {
                        Label("Favorite", systemImage: "heart.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                    
                    if contact.isBlocked {
                        Label("Blocked", systemImage: "slash.circle.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    Label(contact.privacyLevel.displayName, systemImage: "lock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var detailSections: some View {
        VStack(spacing: 20) {
            contactInfoSection
            
            if !contact.tags.isEmpty {
                tagsSection
            }
            
            if let notes = contact.notes, !notes.isEmpty {
                notesSection(notes)
            }
        }
    }
    
    private var contactInfoSection: some View {
        VStack(spacing: 12) {
            if let email = contact.email {
                ContactInfoRow(icon: "envelope", title: "Email", value: email, isLink: true)
            }
            
            if let phone = contact.phoneNumber {
                ContactInfoRow(icon: "phone", title: "Phone", value: phone, isLink: true)
            }
            
            ContactInfoRow(icon: "calendar", title: "Added", value: contact.createdDate.formatted(date: .abbreviated, time: .omitted))
            
            if let lastContacted = contact.lastContactedDate {
                ContactInfoRow(icon: "clock", title: "Last Contact", value: lastContacted.formatted(date: .abbreviated, time: .shortened))
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "tag")
                    .foregroundColor(.secondary)
                Text("Tags")
                    .font(.headline)
                Spacer()
            }
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                ForEach(contact.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.blue.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func notesSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "note.text")
                    .foregroundColor(.secondary)
                Text("Notes")
                    .font(.headline)
                Spacer()
            }
            
            Text(notes)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var editingSection: some View {
        EditContactFormView(contact: $contact)
    }
    
    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(.secondary)
                Text("Recent Activity")
                    .font(.headline)
                Spacer()
            }
            
            if activities.isEmpty {
                Text("No recent activity")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(activities.prefix(5)) { activity in
                    ActivityRowView(activity: activity)
                        .onTapGesture {
                            selectedActivity = activity
                            showingActivityDetail = true
                        }
                }
                
                if activities.count > 5 {
                    Button("View All Activity") {
                        // TODO: Show full activity list
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func loadActivities() {
        activities = contactManager.getContactActivities(for: contact.id)
    }
    
    private func sendSIF() {
        // TODO: Integration with SIF creation
        contactManager.addContactActivity(for: contact.id, type: .sifSent, notes: "SIF sent from contact details")
        loadActivities()
    }
    
    private func toggleFavorite() {
        contactManager.toggleContactFavorite(contact)
        contact.isFavorite.toggle()
        loadActivities()
    }
    
    private func toggleBlocked() {
        contactManager.toggleContactBlocked(contact)
        contact.isBlocked.toggle()
        loadActivities()
    }
    
    private func deleteContact() {
        contactManager.deleteContact(contact)
        presentationMode.wrappedValue.dismiss()
    }
    
    private func saveChanges() {
        contactManager.updateContact(contact)
        isEditing = false
        loadActivities()
    }
}

// MARK: - Contact Info Row
struct ContactInfoRow: View {
    let icon: String
    let title: String
    let value: String
    let isLink: Bool
    
    init(icon: String, title: String, value: String, isLink: Bool = false) {
        self.icon = icon
        self.title = title
        self.value = value
        self.isLink = isLink
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if isLink {
                    Button(value) {
                        if icon == "envelope" {
                            openMail(value)
                        } else if icon == "phone" {
                            openPhone(value)
                        }
                    }
                    .foregroundColor(.blue)
                } else {
                    Text(value)
                        .font(.body)
                }
            }
            
            Spacer()
        }
    }
    
    private func openMail(_ email: String) {
        if let url = URL(string: "mailto:\(email)") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openPhone(_ phone: String) {
        let cleanPhone = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        if let url = URL(string: "tel:\(cleanPhone)") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Activity Row View
struct ActivityRowView: View {
    let activity: ContactActivity
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: activity.activityType.iconName)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.activityType.displayName)
                    .font(.body)
                
                Text(activity.activityDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if activity.sifId != nil {
                Image(systemName: "envelope.badge")
                    .foregroundColor(.blue)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Edit Contact Form
struct EditContactFormView: View {
    @Binding var contact: Contact
    @State private var newTag = ""
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Basic Information")
                    .font(.headline)
                
                TextField("First Name", text: $contact.firstName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Last Name", text: $contact.lastName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Email", text: Binding(
                    get: { contact.email ?? "" },
                    set: { contact.email = $0.isEmpty ? nil : $0 }
                ))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                
                TextField("Phone Number", text: Binding(
                    get: { contact.phoneNumber ?? "" },
                    set: { contact.phoneNumber = $0.isEmpty ? nil : $0 }
                ))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.phonePad)
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Additional Details")
                    .font(.headline)
                
                TextField("Notes", text: Binding(
                    get: { contact.notes ?? "" },
                    set: { contact.notes = $0.isEmpty ? nil : $0 }
                ), axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(3...6)
                
                Picker("Privacy Level", selection: $contact.privacyLevel) {
                    ForEach(ContactPrivacyLevel.allCases, id: \.self) { level in
                        Text(level.displayName).tag(level)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Tags")
                    .font(.headline)
                
                HStack {
                    TextField("Add tag", text: $newTag)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            addTag()
                        }
                    
                    Button("Add") {
                        addTag()
                    }
                    .disabled(newTag.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                
                if !contact.tags.isEmpty {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                        ForEach(contact.tags, id: \.self) { tag in
                            TagView(tag: tag) {
                                contact.tags.removeAll { $0 == tag }
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private func addTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespaces)
        if !trimmedTag.isEmpty && !contact.tags.contains(trimmedTag) {
            contact.tags.append(trimmedTag)
            newTag = ""
        }
    }
}

// MARK: - Preview
struct ContactDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ContactDetailView(
            contact: Contact(firstName: "John", lastName: "Doe", email: "john@example.com"),
            contactManager: ContactManager()
        )
    }
}