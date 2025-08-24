import SwiftUI
import FirebaseAuth

struct AddContactView: View {
    @ObservedObject var addressBookManager: AddressBookManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phoneNumber = ""
    @State private var selectedCategory: ContactCategory = .personal
    @State private var isFavorite = false
    @State private var notes = ""
    
    @State private var showingValidationAlert = false
    @State private var validationErrors: [String] = []
    @State private var isSaving = false
    
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
                        headerView
                        
                        // Form
                        formView
                        
                        // Save Button
                        saveButtonView
                        
                        Spacer(minLength: 50)
                    }
                    .padding()
                }
            }
            .navigationTitle("Add Contact")
            .navigationBarHidden(true)
        }
        .alert("Validation Error", isPresented: $showingValidationAlert) {
            Button("OK") { }
        } message: {
            Text(validationErrors.joined(separator: "\n"))
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Button("Cancel") {
                dismiss()
            }
            .foregroundColor(.white)
            .font(.headline)
            
            Spacer()
            
            Text("Add Contact")
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
    }
    
    // MARK: - Form View
    private var formView: some View {
        VStack(spacing: 20) {
            // Avatar Preview
            avatarPreview
            
            // Basic Information
            basicInfoSection
            
            // Contact Information
            contactInfoSection
            
            // Category Selection
            categorySection
            
            // Notes Section
            notesSection
            
            // Favorite Toggle
            favoriteSection
        }
    }
    
    // MARK: - Avatar Preview
    private var avatarPreview: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: selectedCategory.color).opacity(0.2))
                    .frame(width: 100, height: 100)
                
                if !firstName.isEmpty || !lastName.isEmpty {
                    Text("\(firstName.prefix(1))\(lastName.prefix(1))".uppercased())
                        .font(.title.weight(.bold))
                        .foregroundColor(Color(hex: selectedCategory.color))
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Color(hex: selectedCategory.color))
                }
            }
            .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
            
            Text("Contact Preview")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
    }
    
    // MARK: - Basic Information Section
    private var basicInfoSection: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "Basic Information", iconName: "person.fill")
            
            VStack(spacing: 12) {
                CustomTextField(
                    title: "First Name",
                    text: $firstName,
                    placeholder: "Enter first name",
                    isRequired: true
                )
                
                CustomTextField(
                    title: "Last Name",
                    text: $lastName,
                    placeholder: "Enter last name",
                    isRequired: true
                )
            }
            .padding(20)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.1), radius: 3, y: 2)
        }
    }
    
    // MARK: - Contact Information Section
    private var contactInfoSection: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "Contact Information", iconName: "phone.fill")
            
            VStack(spacing: 12) {
                CustomTextField(
                    title: "Email",
                    text: $email,
                    placeholder: "Enter email address",
                    keyboardType: .emailAddress
                )
                
                CustomTextField(
                    title: "Phone Number",
                    text: $phoneNumber,
                    placeholder: "Enter phone number",
                    keyboardType: .phonePad
                )
            }
            .padding(20)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.1), radius: 3, y: 2)
        }
    }
    
    // MARK: - Category Section
    private var categorySection: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "Category", iconName: "folder.fill")
            
            VStack(spacing: 0) {
                ForEach(ContactCategory.allCases, id: \.self) { category in
                    CategoryRow(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                    
                    if category != ContactCategory.allCases.last {
                        Divider()
                            .padding(.leading, 60)
                    }
                }
            }
            .padding(20)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.1), radius: 3, y: 2)
        }
    }
    
    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "Notes", iconName: "note.text")
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Notes (Optional)")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(Color.brandDarkBlue)
                
                TextEditor(text: $notes)
                    .frame(minHeight: 80)
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(20)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.1), radius: 3, y: 2)
        }
    }
    
    // MARK: - Favorite Section
    private var favoriteSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Add to Favorites")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.white)
                    
                    Text("Mark this contact as a favorite for quick access")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                Toggle("", isOn: $isFavorite)
                    .toggleStyle(SwitchToggleStyle(tint: .red))
            }
            .padding(20)
            .background(.white.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    // MARK: - Save Button View
    private var saveButtonView: some View {
        Button(action: saveContact) {
            HStack {
                if isSaving {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white)
                } else {
                    Image(systemName: "checkmark")
                        .font(.headline.weight(.bold))
                }
                
                Text(isSaving ? "Saving..." : "Save Contact")
                    .font(.headline.weight(.semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(isFormValid ? Color.brandDarkBlue : Color.gray)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.2), radius: 5, y: 3)
        }
        .disabled(!isFormValid || isSaving)
    }
    
    // MARK: - Save Contact Function
    private func saveContact() {
        guard let uid = Auth.auth().currentUser?.uid else {
            validationErrors = ["User not authenticated"]
            showingValidationAlert = true
            return
        }
        
        let contact = Contact(
            ownerUid: uid,
            firstName: firstName.trimmingCharacters(in: .whitespaces),
            lastName: lastName.trimmingCharacters(in: .whitespaces),
            email: email.trimmingCharacters(in: .whitespaces).isEmpty ? nil : email.trimmingCharacters(in: .whitespaces),
            phoneNumber: phoneNumber.trimmingCharacters(in: .whitespaces).isEmpty ? nil : phoneNumber.trimmingCharacters(in: .whitespaces),
            category: selectedCategory,
            isFavorite: isFavorite,
            notes: notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes.trimmingCharacters(in: .whitespaces)
        )
        
        // Validate contact
        let errors = addressBookManager.validateContact(contact)
        if !errors.isEmpty {
            validationErrors = errors
            showingValidationAlert = true
            return
        }
        
        // Save contact
        isSaving = true
        Task {
            do {
                try await addressBookManager.addContact(contact)
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

private struct CustomTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var isRequired: Bool = false
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(Color.brandDarkBlue)
                
                if isRequired {
                    Text("*")
                        .foregroundColor(.red)
                        .font(.subheadline.weight(.bold))
                }
                
                Spacer()
            }
            
            TextField(placeholder, text: $text)
                .textFieldStyle(PillTextFieldStyle())
                .keyboardType(keyboardType)
        }
    }
}

private struct CategoryRow: View {
    let category: ContactCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color(hex: category.color).opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: category.iconName)
                        .foregroundColor(Color(hex: category.color))
                        .font(.headline)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.rawValue)
                        .font(.headline.weight(.medium))
                        .foregroundColor(Color.brandDarkBlue)
                    
                    Text(getCategoryDescription(category))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.brandDarkBlue)
                        .font(.title3)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func getCategoryDescription(_ category: ContactCategory) -> String {
        switch category {
        case .personal:
            return "Personal contacts and acquaintances"
        case .work:
            return "Work colleagues and professional contacts"
        case .family:
            return "Family members and relatives"
        case .friends:
            return "Friends and close personal contacts"
        case .business:
            return "Business contacts and vendors"
        case .other:
            return "Other contacts"
        }
    }
}

struct AddContactView_Previews: PreviewProvider {
    static var previews: some View {
        AddContactView(addressBookManager: AddressBookManager())
    }
}