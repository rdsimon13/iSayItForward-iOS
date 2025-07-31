import SwiftUI
import PhotosUI

struct AddContactView: View {
    @ObservedObject var contactManager: ContactManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phoneNumber = ""
    @State private var notes = ""
    @State private var isFavorite = false
    @State private var privacyLevel = ContactPrivacyLevel.normal
    @State private var tags: [String] = []
    @State private var newTag = ""
    @State private var selectedImageData: Data?
    @State private var showingImagePicker = false
    @State private var showingValidationAlert = false
    @State private var validationMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Basic Information") {
                    HStack {
                        contactAvatarSection
                        
                        VStack(spacing: 12) {
                            TextField("First Name", text: $firstName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            TextField("Last Name", text: $lastName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    .padding(.vertical, 8)
                    
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    TextField("Phone Number", text: $phoneNumber)
                        .keyboardType(.phonePad)
                }
                
                Section("Additional Information") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                    
                    Toggle("Add to Favorites", isOn: $isFavorite)
                    
                    Picker("Privacy Level", selection: $privacyLevel) {
                        ForEach(ContactPrivacyLevel.allCases, id: \.self) { level in
                            VStack(alignment: .leading) {
                                Text(level.displayName)
                                Text(level.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .tag(level)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("Tags") {
                    HStack {
                        TextField("Add tag", text: $newTag)
                            .onSubmit {
                                addTag()
                            }
                        
                        Button("Add") {
                            addTag()
                        }
                        .disabled(newTag.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    
                    if !tags.isEmpty {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                            ForEach(tags, id: \.self) { tag in
                                TagView(tag: tag) {
                                    removeTag(tag)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveContact()
                    }
                    .disabled(!isValidInput)
                }
            }
            .alert("Validation Error", isPresented: $showingValidationAlert) {
                Button("OK") { }
            } message: {
                Text(validationMessage)
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImageData: $selectedImageData)
            }
        }
    }
    
    private var contactAvatarSection: some View {
        VStack {
            Button(action: {
                showingImagePicker = true
            }) {
                Group {
                    if let imageData = selectedImageData,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 80, height: 80)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.secondary.opacity(0.3), lineWidth: 1))
            }
            
            Text("Add Photo")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var isValidInput: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private func addTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespaces)
        if !trimmedTag.isEmpty && !tags.contains(trimmedTag) {
            tags.append(trimmedTag)
            newTag = ""
        }
    }
    
    private func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
    
    private func saveContact() {
        guard validateInput() else { return }
        
        let contact = Contact(
            firstName: firstName.trimmingCharacters(in: .whitespaces),
            lastName: lastName.trimmingCharacters(in: .whitespaces),
            email: email.trimmingCharacters(in: .whitespaces).isEmpty ? nil : email.trimmingCharacters(in: .whitespaces),
            phoneNumber: phoneNumber.trimmingCharacters(in: .whitespaces).isEmpty ? nil : phoneNumber.trimmingCharacters(in: .whitespaces)
        )
        
        var newContact = contact
        newContact.notes = notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes.trimmingCharacters(in: .whitespaces)
        newContact.isFavorite = isFavorite
        newContact.privacyLevel = privacyLevel
        newContact.tags = tags
        newContact.avatarImageData = selectedImageData
        
        contactManager.addContact(newContact)
        presentationMode.wrappedValue.dismiss()
    }
    
    private func validateInput() -> Bool {
        if firstName.trimmingCharacters(in: .whitespaces).isEmpty {
            validationMessage = "First name is required."
            showingValidationAlert = true
            return false
        }
        
        let emailText = email.trimmingCharacters(in: .whitespaces)
        if !emailText.isEmpty && !isValidEmail(emailText) {
            validationMessage = "Please enter a valid email address."
            showingValidationAlert = true
            return false
        }
        
        let phoneText = phoneNumber.trimmingCharacters(in: .whitespaces)
        if !phoneText.isEmpty && !isValidPhoneNumber(phoneText) {
            validationMessage = "Please enter a valid phone number."
            showingValidationAlert = true
            return false
        }
        
        if emailText.isEmpty && phoneText.isEmpty {
            validationMessage = "Please provide either an email address or phone number."
            showingValidationAlert = true
            return false
        }
        
        return true
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }
    
    private func isValidPhoneNumber(_ phone: String) -> Bool {
        let phoneRegex = #"^[\d\s\-\(\)\+\.]{7,}$"#
        return phone.range(of: phoneRegex, options: .regularExpression) != nil
    }
}

// MARK: - Tag View Component
struct TagView: View {
    let tag: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(.caption)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.blue.opacity(0.2))
        .clipShape(Capsule())
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImageData: Data?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.selectedImageData = editedImage.jpegData(compressionQuality: 0.8)
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.selectedImageData = originalImage.jpegData(compressionQuality: 0.8)
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Preview
struct AddContactView_Previews: PreviewProvider {
    static var previews: some View {
        AddContactView(contactManager: ContactManager())
    }
}