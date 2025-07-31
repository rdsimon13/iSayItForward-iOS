import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

// Manager class for handling Contact CRUD operations with Firebase
class AddressBookManager: ObservableObject {
    @Published var contacts: [Contact] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var db = Firestore.firestore()
    private var contactsListener: ListenerRegistration?
    
    // MARK: - Initialization
    init() {
        startListening()
    }
    
    deinit {
        stopListening()
    }
    
    // MARK: - Real-time listener
    private func startListening() {
        guard let uid = Auth.auth().currentUser?.uid else {
            self.errorMessage = "User not authenticated"
            return
        }
        
        isLoading = true
        contactsListener = db.collection("contacts")
            .whereField("ownerUid", isEqualTo: uid)
            .order(by: "firstName")
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        self?.errorMessage = "Error loading contacts: \(error.localizedDescription)"
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        self?.errorMessage = "No contacts found"
                        return
                    }
                    
                    do {
                        self?.contacts = try documents.compactMap { document in
                            try document.data(as: Contact.self)
                        }
                        self?.errorMessage = nil
                    } catch {
                        self?.errorMessage = "Error parsing contacts: \(error.localizedDescription)"
                    }
                }
            }
    }
    
    private func stopListening() {
        contactsListener?.remove()
    }
    
    // MARK: - CRUD Operations
    
    /// Add a new contact
    func addContact(_ contact: Contact) async throws {
        guard Auth.auth().currentUser?.uid != nil else {
            throw AddressBookError.userNotAuthenticated
        }
        
        do {
            _ = try db.collection("contacts").addDocument(from: contact)
        } catch {
            throw AddressBookError.addFailed(error.localizedDescription)
        }
    }
    
    /// Update an existing contact
    func updateContact(_ contact: Contact) async throws {
        guard let contactId = contact.id else {
            throw AddressBookError.invalidContactId
        }
        
        var updatedContact = contact
        updatedContact.updatedDate = Date()
        
        do {
            try db.collection("contacts").document(contactId).setData(from: updatedContact)
        } catch {
            throw AddressBookError.updateFailed(error.localizedDescription)
        }
    }
    
    /// Delete a contact
    func deleteContact(_ contact: Contact) async throws {
        guard let contactId = contact.id else {
            throw AddressBookError.invalidContactId
        }
        
        do {
            try await db.collection("contacts").document(contactId).delete()
        } catch {
            throw AddressBookError.deleteFailed(error.localizedDescription)
        }
    }
    
    /// Toggle favorite status
    func toggleFavorite(_ contact: Contact) async throws {
        var updatedContact = contact
        updatedContact.isFavorite.toggle()
        try await updateContact(updatedContact)
    }
    
    // MARK: - Filtering and Searching
    
    /// Get contacts filtered by category
    func contactsByCategory(_ category: ContactCategory) -> [Contact] {
        return contacts.filter { $0.category == category }
    }
    
    /// Get favorite contacts
    var favoriteContacts: [Contact] {
        return contacts.filter { $0.isFavorite }
    }
    
    /// Search contacts by name or email
    func searchContacts(_ searchText: String) -> [Contact] {
        if searchText.isEmpty {
            return contacts
        }
        
        return contacts.filter { contact in
            contact.fullName.localizedCaseInsensitiveContains(searchText) ||
            contact.email?.localizedCaseInsensitiveContains(searchText) == true ||
            contact.phoneNumber?.localizedCaseInsensitiveContains(searchText) == true
        }
    }
    
    // MARK: - Validation
    
    /// Validate contact data before saving
    func validateContact(_ contact: Contact) -> [String] {
        var errors: [String] = []
        
        if contact.firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
           contact.lastName.trimmingCharacters(in: .whitespaces).isEmpty {
            errors.append("At least first name or last name is required")
        }
        
        if let email = contact.email, !email.isEmpty {
            if !isValidEmail(email) {
                errors.append("Invalid email format")
            }
        }
        
        if let phone = contact.phoneNumber, !phone.isEmpty {
            if !isValidPhoneNumber(phone) {
                errors.append("Invalid phone number format")
            }
        }
        
        return errors
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func isValidPhoneNumber(_ phone: String) -> Bool {
        // Simple phone validation - allows digits, spaces, dashes, parentheses
        let phoneRegex = "^[\\d\\s\\-\\(\\)\\+]{7,15}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phonePredicate.evaluate(with: phone)
    }
}

// MARK: - Error Handling
enum AddressBookError: LocalizedError {
    case userNotAuthenticated
    case invalidContactId
    case addFailed(String)
    case updateFailed(String)
    case deleteFailed(String)
    case validationFailed([String])
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User not authenticated"
        case .invalidContactId:
            return "Invalid contact ID"
        case .addFailed(let message):
            return "Failed to add contact: \(message)"
        case .updateFailed(let message):
            return "Failed to update contact: \(message)"
        case .deleteFailed(let message):
            return "Failed to delete contact: \(message)"
        case .validationFailed(let errors):
            return "Validation failed: \(errors.joined(separator: ", "))"
        }
    }
}