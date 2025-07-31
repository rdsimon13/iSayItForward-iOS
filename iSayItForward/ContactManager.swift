import Foundation
import CoreData
import Combine

// MARK: - Contact Manager Service
class ContactManager: ObservableObject {
    private let persistenceManager = PersistenceManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    @Published var contacts: [Contact] = []
    @Published var contactGroups: [ContactGroup] = []
    @Published var isLoading = false
    @Published var error: ContactError?
    
    init() {
        loadContacts()
        loadContactGroups()
        createSystemGroupsIfNeeded()
    }
    
    // MARK: - Contact CRUD Operations
    
    func addContact(_ contact: Contact) {
        let context = persistenceManager.context
        let entity = ContactEntity(context: context)
        entity.updateFromContact(contact)
        
        saveContext()
        loadContacts()
        
        // Add activity
        addContactActivity(for: contact.id, type: .contactAdded)
    }
    
    func updateContact(_ contact: Contact) {
        let context = persistenceManager.context
        let request: NSFetchRequest<ContactEntity> = ContactEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", contact.id as CVarArg)
        
        do {
            let entities = try context.fetch(request)
            if let entity = entities.first {
                entity.updateFromContact(contact)
                saveContext()
                loadContacts()
                
                // Add activity
                addContactActivity(for: contact.id, type: .contactEdited)
            }
        } catch {
            self.error = .updateFailed(error.localizedDescription)
        }
    }
    
    func deleteContact(_ contact: Contact) {
        let context = persistenceManager.context
        let request: NSFetchRequest<ContactEntity> = ContactEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", contact.id as CVarArg)
        
        do {
            let entities = try context.fetch(request)
            if let entity = entities.first {
                context.delete(entity)
                saveContext()
                loadContacts()
            }
        } catch {
            self.error = .deleteFailed(error.localizedDescription)
        }
    }
    
    func toggleContactBlocked(_ contact: Contact) {
        var updatedContact = contact
        updatedContact.isBlocked.toggle()
        updateContact(updatedContact)
        
        // Add activity
        let activityType: ContactActivityType = updatedContact.isBlocked ? .contactBlocked : .contactUnblocked
        addContactActivity(for: contact.id, type: activityType)
    }
    
    func toggleContactFavorite(_ contact: Contact) {
        var updatedContact = contact
        updatedContact.isFavorite.toggle()
        updateContact(updatedContact)
        
        // Add activity
        let activityType: ContactActivityType = updatedContact.isFavorite ? .contactFavorited : .contactUnfavorited
        addContactActivity(for: contact.id, type: activityType)
    }
    
    // MARK: - Contact Group Operations
    
    func addContactGroup(_ group: ContactGroup) {
        let context = persistenceManager.context
        let entity = ContactGroupEntity(context: context)
        entity.updateFromContactGroup(group)
        
        saveContext()
        loadContactGroups()
    }
    
    func updateContactGroup(_ group: ContactGroup) {
        let context = persistenceManager.context
        let request: NSFetchRequest<ContactGroupEntity> = ContactGroupEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", group.id as CVarArg)
        
        do {
            let entities = try context.fetch(request)
            if let entity = entities.first {
                entity.updateFromContactGroup(group)
                saveContext()
                loadContactGroups()
            }
        } catch {
            self.error = .updateFailed(error.localizedDescription)
        }
    }
    
    func deleteContactGroup(_ group: ContactGroup) {
        guard !group.isSystemGroup else { return } // Don't delete system groups
        
        let context = persistenceManager.context
        let request: NSFetchRequest<ContactGroupEntity> = ContactGroupEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", group.id as CVarArg)
        
        do {
            let entities = try context.fetch(request)
            if let entity = entities.first {
                context.delete(entity)
                saveContext()
                loadContactGroups()
            }
        } catch {
            self.error = .deleteFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Contact Activity Operations
    
    func addContactActivity(for contactId: UUID, type: ContactActivityType, sifId: String? = nil, notes: String? = nil) {
        let activity = ContactActivity(activityType: type, sifId: sifId, notes: notes)
        
        let context = persistenceManager.context
        let entity = ContactActivityEntity(context: context)
        entity.updateFromContactActivity(activity)
        
        // Link to contact
        let contactRequest: NSFetchRequest<ContactEntity> = ContactEntity.fetchRequest()
        contactRequest.predicate = NSPredicate(format: "id == %@", contactId as CVarArg)
        
        do {
            let contactEntities = try context.fetch(contactRequest)
            if let contactEntity = contactEntities.first {
                entity.contact = contactEntity
                
                // Update last contacted date for SIF activities
                if type == .sifSent || type == .sifReceived {
                    contactEntity.lastContactedDate = Date()
                }
            }
        } catch {
            self.error = .updateFailed(error.localizedDescription)
        }
        
        saveContext()
    }
    
    func getContactActivities(for contactId: UUID) -> [ContactActivity] {
        let context = persistenceManager.context
        let request: NSFetchRequest<ContactActivityEntity> = ContactActivityEntity.fetchRequest()
        request.predicate = NSPredicate(format: "contact.id == %@", contactId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ContactActivityEntity.activityDate, ascending: false)]
        
        do {
            let entities = try context.fetch(request)
            return entities.map { $0.toContactActivity() }
        } catch {
            self.error = .loadFailed(error.localizedDescription)
            return []
        }
    }
    
    // MARK: - Search and Filter Operations
    
    func searchContacts(query: String) -> [Contact] {
        guard !query.isEmpty else { return contacts }
        
        return contacts.filter { contact in
            contact.fullName.localizedCaseInsensitiveContains(query) ||
            contact.email?.localizedCaseInsensitiveContains(query) == true ||
            contact.phoneNumber?.localizedCaseInsensitiveContains(query) == true ||
            contact.notes?.localizedCaseInsensitiveContains(query) == true
        }
    }
    
    func getContactsByGroup(_ group: ContactGroup) -> [Contact] {
        switch group.name {
        case "Favorites":
            return contacts.filter { $0.isFavorite }
        case "Recent":
            return contacts
                .filter { $0.lastContactedDate != nil }
                .sorted { ($0.lastContactedDate ?? Date.distantPast) > ($1.lastContactedDate ?? Date.distantPast) }
                .prefix(20)
                .map { $0 }
        case "Blocked":
            return contacts.filter { $0.isBlocked }
        default:
            // TODO: Implement custom group filtering when many-to-many relationships are added
            return []
        }
    }
    
    func getContactsByTag(_ tag: String) -> [Contact] {
        return contacts.filter { $0.tags.contains(tag) }
    }
    
    // MARK: - Private Helper Methods
    
    private func loadContacts() {
        isLoading = true
        let context = persistenceManager.context
        let request: NSFetchRequest<ContactEntity> = ContactEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ContactEntity.firstName, ascending: true)]
        
        do {
            let entities = try context.fetch(request)
            DispatchQueue.main.async {
                self.contacts = entities.map { $0.toContact() }
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.error = .loadFailed(error.localizedDescription)
                self.isLoading = false
            }
        }
    }
    
    private func loadContactGroups() {
        let context = persistenceManager.context
        let request: NSFetchRequest<ContactGroupEntity> = ContactGroupEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ContactGroupEntity.name, ascending: true)]
        
        do {
            let entities = try context.fetch(request)
            DispatchQueue.main.async {
                self.contactGroups = entities.map { $0.toContactGroup() }
            }
        } catch {
            DispatchQueue.main.async {
                self.error = .loadFailed(error.localizedDescription)
            }
        }
    }
    
    private func createSystemGroupsIfNeeded() {
        let existingGroups = contactGroups.map { $0.name }
        
        for systemGroup in ContactGroup.allSystemGroups {
            if !existingGroups.contains(systemGroup.name) {
                addContactGroup(systemGroup)
            }
        }
    }
    
    private func saveContext() {
        persistenceManager.save()
    }
}

// MARK: - Contact Error Types
enum ContactError: LocalizedError {
    case loadFailed(String)
    case saveFailed(String)
    case updateFailed(String)
    case deleteFailed(String)
    case invalidData(String)
    case permissionDenied(String)
    
    var errorDescription: String? {
        switch self {
        case .loadFailed(let message):
            return "Failed to load contacts: \(message)"
        case .saveFailed(let message):
            return "Failed to save contact: \(message)"
        case .updateFailed(let message):
            return "Failed to update contact: \(message)"
        case .deleteFailed(let message):
            return "Failed to delete contact: \(message)"
        case .invalidData(let message):
            return "Invalid contact data: \(message)"
        case .permissionDenied(let message):
            return "Permission denied: \(message)"
        }
    }
}