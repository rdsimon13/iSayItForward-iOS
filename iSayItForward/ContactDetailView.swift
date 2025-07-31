import SwiftUI
import MessageUI

struct ContactDetailView: View {
    let contact: Contact
    @ObservedObject var addressBookManager: AddressBookManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var isEditing = false
    @State private var showingDeleteAlert = false
    @State private var showingMailComposer = false
    @State private var showingMessageComposer = false
    @State private var showingEditView = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.mainAppGradient.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header with avatar and basic info
                        headerView
                        
                        // Contact actions
                        contactActionsView
                        
                        // Contact information
                        contactInfoView
                        
                        // Notes section
                        if let notes = contact.notes, !notes.isEmpty {
                            notesView
                        }
                        
                        // Category and metadata
                        metadataView
                        
                        Spacer(minLength: 50)
                    }
                    .padding()
                }
            }
            .navigationTitle("Contact")
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingEditView) {
            EditContactView(contact: contact, addressBookManager: addressBookManager)
        }
        .sheet(isPresented: $showingMailComposer) {
            if let email = contact.email {
                MailComposeView(recipients: [email], subject: "", body: "")
            }
        }
        .sheet(isPresented: $showingMessageComposer) {
            if let phone = contact.phoneNumber {
                MessageComposeView(recipients: [phone], body: "")
            }
        }
        .alert("Delete Contact", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    try? await addressBookManager.deleteContact(contact)
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to delete \(contact.displayName)? This action cannot be undone.")
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 20) {
            // Navigation buttons
            HStack {
                Button("Close") {
                    dismiss()
                }
                .foregroundColor(.white)
                .font(.headline)
                
                Spacer()
                
                HStack(spacing: 16) {
                    // Favorite button
                    Button(action: toggleFavorite) {
                        Image(systemName: contact.isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(contact.isFavorite ? .red : .white)
                            .font(.title3)
                    }
                    
                    // Edit button
                    Button("Edit") {
                        showingEditView = true
                    }
                    .foregroundColor(.white)
                    .font(.headline.weight(.semibold))
                }
            }
            
            // Avatar and name
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color(hex: contact.category.color).opacity(0.2))
                        .frame(width: 120, height: 120)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 3)
                        )
                    
                    Text(contact.displayName.prefix(2).uppercased())
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(Color(hex: contact.category.color))
                }
                .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                
                VStack(spacing: 8) {
                    Text(contact.displayName)
                        .font(.title.weight(.bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 8) {
                        Image(systemName: contact.category.iconName)
                            .foregroundColor(Color(hex: contact.category.color))
                        Text(contact.category.rawValue)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .font(.subheadline.weight(.medium))
                }
            }
        }
    }
    
    // MARK: - Contact Actions View
    private var contactActionsView: some View {
        HStack(spacing: 16) {
            // Call button
            if let phone = contact.phoneNumber, !phone.isEmpty {
                ContactActionButton(
                    iconName: "phone.fill",
                    title: "Call",
                    color: .green
                ) {
                    callContact()
                }
            }
            
            // Message button
            if let phone = contact.phoneNumber, !phone.isEmpty {
                ContactActionButton(
                    iconName: "message.fill",
                    title: "Message",
                    color: .blue
                ) {
                    showingMessageComposer = true
                }
            }
            
            // Email button
            if let email = contact.email, !email.isEmpty {
                ContactActionButton(
                    iconName: "envelope.fill",
                    title: "Email",
                    color: Color.brandDarkBlue
                ) {
                    showingMailComposer = true
                }
            }
            
            // Delete button
            ContactActionButton(
                iconName: "trash.fill",
                title: "Delete",
                color: .red
            ) {
                showingDeleteAlert = true
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Contact Info View
    private var contactInfoView: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "Contact Information", iconName: "person.crop.circle.fill")
            
            VStack(spacing: 0) {
                // Email
                if let email = contact.email, !email.isEmpty {
                    ContactInfoRow(
                        iconName: "envelope.fill",
                        title: "Email",
                        value: email,
                        color: Color.brandDarkBlue
                    ) {
                        showingMailComposer = true
                    }
                    
                    Divider()
                        .padding(.leading, 60)
                }
                
                // Phone
                if let phone = contact.phoneNumber, !phone.isEmpty {
                    ContactInfoRow(
                        iconName: "phone.fill",
                        title: "Phone",
                        value: phone,
                        color: .green
                    ) {
                        callContact()
                    }
                }
                
                // Show message if no contact info
                if (contact.email?.isEmpty ?? true) && (contact.phoneNumber?.isEmpty ?? true) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("No contact information available")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding()
                }
            }
            .padding(20)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.1), radius: 3, y: 2)
        }
    }
    
    // MARK: - Notes View
    private var notesView: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "Notes", iconName: "note.text")
            
            VStack(alignment: .leading, spacing: 12) {
                Text(contact.notes ?? "")
                    .font(.body)
                    .foregroundColor(Color.brandDarkBlue)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(20)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.1), radius: 3, y: 2)
        }
    }
    
    // MARK: - Metadata View
    private var metadataView: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "Details", iconName: "info.circle.fill")
            
            VStack(spacing: 0) {
                MetadataRow(
                    iconName: "calendar.badge.plus",
                    title: "Created",
                    value: formatDate(contact.createdDate)
                )
                
                Divider()
                    .padding(.leading, 60)
                
                MetadataRow(
                    iconName: "calendar.badge.clock",
                    title: "Last Updated",
                    value: formatDate(contact.updatedDate)
                )
                
                if contact.isFavorite {
                    Divider()
                        .padding(.leading, 60)
                    
                    MetadataRow(
                        iconName: "heart.fill",
                        title: "Favorite",
                        value: "Yes",
                        valueColor: .red
                    )
                }
            }
            .padding(20)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.1), radius: 3, y: 2)
        }
    }
    
    // MARK: - Helper Functions
    
    private func toggleFavorite() {
        Task {
            try? await addressBookManager.toggleFavorite(contact)
        }
    }
    
    private func callContact() {
        guard let phone = contact.phoneNumber?.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: ""),
              let phoneURL = URL(string: "tel://\(phone)") else {
            return
        }
        
        if UIApplication.shared.canOpenURL(phoneURL) {
            UIApplication.shared.open(phoneURL)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views

private struct SectionHeader: View {
    let title: String
    let iconName: String
    
    var body: some View {
        HStack {
            Image(systemName: iconName)
                .foregroundColor(.white)
                .font(.headline)
            
            Text(title)
                .font(.headline.weight(.bold))
                .foregroundColor(.white)
            
            Spacer()
        }
    }
}

private struct ContactActionButton: View {
    let iconName: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color)
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: iconName)
                        .foregroundColor(.white)
                        .font(.title3.weight(.semibold))
                }
                
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundColor(.white)
            }
        }
    }
}

private struct ContactInfoRow: View {
    let iconName: String
    let title: String
    let value: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: iconName)
                        .foregroundColor(color)
                        .font(.headline)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.secondary)
                    
                    Text(value)
                        .font(.body.weight(.medium))
                        .foregroundColor(Color.brandDarkBlue)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption.weight(.semibold))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.vertical, 4)
    }
}

private struct MetadataRow: View {
    let iconName: String
    let title: String
    let value: String
    var valueColor: Color = Color.brandDarkBlue
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: iconName)
                .foregroundColor(.secondary)
                .font(.headline)
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundColor(valueColor)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Mail and Message Composers

struct MailComposeView: UIViewControllerRepresentable {
    let recipients: [String]
    let subject: String
    let body: String
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.setToRecipients(recipients)
        composer.setSubject(subject)
        composer.setMessageBody(body, isHTML: false)
        composer.mailComposeDelegate = context.coordinator
        return composer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: MailComposeView
        
        init(_ parent: MailComposeView) {
            self.parent = parent
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            controller.dismiss(animated: true)
        }
    }
}

struct MessageComposeView: UIViewControllerRepresentable {
    let recipients: [String]
    let body: String
    
    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let composer = MFMessageComposeViewController()
        composer.recipients = recipients
        composer.body = body
        composer.messageComposeDelegate = context.coordinator
        return composer
    }
    
    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        let parent: MessageComposeView
        
        init(_ parent: MessageComposeView) {
            self.parent = parent
        }
        
        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            controller.dismiss(animated: true)
        }
    }
}

// MARK: - Edit Contact View (Simplified version of AddContactView)

struct EditContactView: View {
    let contact: Contact
    @ObservedObject var addressBookManager: AddressBookManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var firstName: String
    @State private var lastName: String
    @State private var email: String
    @State private var phoneNumber: String
    @State private var selectedCategory: ContactCategory
    @State private var isFavorite: Bool
    @State private var notes: String
    
    @State private var showingValidationAlert = false
    @State private var validationErrors: [String] = []
    @State private var isSaving = false
    
    init(contact: Contact, addressBookManager: AddressBookManager) {
        self.contact = contact
        self.addressBookManager = addressBookManager
        
        _firstName = State(initialValue: contact.firstName)
        _lastName = State(initialValue: contact.lastName)
        _email = State(initialValue: contact.email ?? "")
        _phoneNumber = State(initialValue: contact.phoneNumber ?? "")
        _selectedCategory = State(initialValue: contact.category)
        _isFavorite = State(initialValue: contact.isFavorite)
        _notes = State(initialValue: contact.notes ?? "")
    }
    
    private var isFormValid: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty ||
        !lastName.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.mainAppGradient.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        HStack {
                            Button("Cancel") {
                                dismiss()
                            }
                            .foregroundColor(.white)
                            .font(.headline)
                            
                            Spacer()
                            
                            Text("Edit Contact")
                                .font(.title2.weight(.bold))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button("Save") {
                                saveContact()
                            }
                            .foregroundColor(.white)
                            .font(.headline.weight(.semibold))
                            .disabled(!isFormValid || isSaving)
                            .opacity(isFormValid && !isSaving ? 1 : 0.6)
                        }
                        
                        // Use similar form structure as AddContactView
                        // For brevity, I'll include just the essential fields
                        VStack(spacing: 20) {
                            // Basic fields similar to AddContactView
                            VStack(spacing: 12) {
                                TextField("First Name", text: $firstName)
                                    .textFieldStyle(PillTextFieldStyle())
                                
                                TextField("Last Name", text: $lastName)
                                    .textFieldStyle(PillTextFieldStyle())
                                
                                TextField("Email", text: $email)
                                    .textFieldStyle(PillTextFieldStyle())
                                    .keyboardType(.emailAddress)
                                
                                TextField("Phone Number", text: $phoneNumber)
                                    .textFieldStyle(PillTextFieldStyle())
                                    .keyboardType(.phonePad)
                            }
                            .padding(20)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .black.opacity(0.1), radius: 3, y: 2)
                        }
                        
                        Spacer(minLength: 50)
                    }
                    .padding()
                }
            }
            .navigationTitle("Edit Contact")
            .navigationBarHidden(true)
        }
        .alert("Validation Error", isPresented: $showingValidationAlert) {
            Button("OK") { }
        } message: {
            Text(validationErrors.joined(separator: "\n"))
        }
    }
    
    private func saveContact() {
        var updatedContact = contact
        updatedContact.firstName = firstName.trimmingCharacters(in: .whitespaces)
        updatedContact.lastName = lastName.trimmingCharacters(in: .whitespaces)
        updatedContact.email = email.trimmingCharacters(in: .whitespaces).isEmpty ? nil : email.trimmingCharacters(in: .whitespaces)
        updatedContact.phoneNumber = phoneNumber.trimmingCharacters(in: .whitespaces).isEmpty ? nil : phoneNumber.trimmingCharacters(in: .whitespaces)
        updatedContact.category = selectedCategory
        updatedContact.isFavorite = isFavorite
        updatedContact.notes = notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes.trimmingCharacters(in: .whitespaces)
        
        // Validate contact
        let errors = addressBookManager.validateContact(updatedContact)
        if !errors.isEmpty {
            validationErrors = errors
            showingValidationAlert = true
            return
        }
        
        // Save contact
        isSaving = true
        Task {
            do {
                try await addressBookManager.updateContact(updatedContact)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    validationErrors = [error.localizedDescription]
                    showingValidationAlert = true
                    isSaving = false
                }
            }
        }
    }
}

struct ContactDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleContact = Contact(
            ownerUid: "test",
            firstName: "John",
            lastName: "Doe",
            email: "john.doe@example.com",
            phoneNumber: "+1 (555) 123-4567",
            category: .work,
            isFavorite: true,
            notes: "Important business contact"
        )
        
        ContactDetailView(contact: sampleContact, addressBookManager: AddressBookManager())
    }
}