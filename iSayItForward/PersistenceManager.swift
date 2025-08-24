import Foundation
import CoreData

// MARK: - Core Data Persistence Manager
class PersistenceManager: ObservableObject {
    static let shared = PersistenceManager()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "ContactDataModel")
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Core Data error: \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func save() {
        let context = persistentContainer.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private init() {}
}

// MARK: - CoreData Extensions for Contact Models
extension ContactEntity {
    func toContact() -> Contact {
        var contact = Contact(
            id: self.id ?? UUID(),
            firstName: self.firstName ?? "",
            lastName: self.lastName ?? "",
            email: self.email,
            phoneNumber: self.phoneNumber
        )
        
        contact.notes = self.notes
        contact.isBlocked = self.isBlocked
        contact.isFavorite = self.isFavorite
        contact.createdDate = self.createdDate ?? Date()
        contact.lastContactedDate = self.lastContactedDate
        contact.privacyLevel = ContactPrivacyLevel(rawValue: self.privacyLevel) ?? .normal
        contact.tags = self.tags?.components(separatedBy: ",").filter { !$0.isEmpty } ?? []
        contact.avatarImageData = self.avatarImageData
        contact.firebaseId = self.firebaseId
        
        return contact
    }
    
    func updateFromContact(_ contact: Contact) {
        self.id = contact.id
        self.firstName = contact.firstName
        self.lastName = contact.lastName
        self.email = contact.email
        self.phoneNumber = contact.phoneNumber
        self.notes = contact.notes
        self.isBlocked = contact.isBlocked
        self.isFavorite = contact.isFavorite
        self.createdDate = contact.createdDate
        self.lastContactedDate = contact.lastContactedDate
        self.privacyLevel = contact.privacyLevel.rawValue
        self.tags = contact.tags.joined(separator: ",")
        self.avatarImageData = contact.avatarImageData
        self.firebaseId = contact.firebaseId
    }
}

extension ContactGroupEntity {
    func toContactGroup() -> ContactGroup {
        return ContactGroup(
            id: self.id ?? UUID(),
            name: self.name ?? "",
            colorHex: self.colorHex ?? "#007AFF",
            isSystemGroup: self.isSystemGroup
        )
    }
    
    func updateFromContactGroup(_ group: ContactGroup) {
        self.id = group.id
        self.name = group.name
        self.colorHex = group.colorHex
        self.createdDate = group.createdDate
        self.isSystemGroup = group.isSystemGroup
    }
}

extension ContactActivityEntity {
    func toContactActivity() -> ContactActivity {
        return ContactActivity(
            id: self.id ?? UUID(),
            activityType: ContactActivityType(rawValue: self.activityType ?? "") ?? .contactAdded,
            sifId: self.sifId,
            notes: self.notes
        )
    }
    
    func updateFromContactActivity(_ activity: ContactActivity) {
        self.id = activity.id
        self.activityType = activity.activityType.rawValue
        self.activityDate = activity.activityDate
        self.sifId = activity.sifId
        self.notes = activity.notes
    }
}