import XCTest
import CoreData
@testable import iSayItForward

class ContactManagerTests: XCTestCase {
    var contactManager: ContactManager!
    var testContext: NSManagedObjectContext!
    
    override func setUp() {
        super.setUp()
        
        // Create an in-memory Core Data stack for testing
        let persistentContainer = NSPersistentContainer(name: "ContactDataModel")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        persistentContainer.persistentStoreDescriptions = [description]
        
        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load store: \(error)")
            }
        }
        
        testContext = persistentContainer.viewContext
        
        // Initialize ContactManager with test context
        contactManager = ContactManager()
        
        // Override the persistence manager for testing
        let testPersistenceManager = PersistenceManager.shared
        testPersistenceManager.persistentContainer = persistentContainer
    }
    
    override func tearDown() {
        contactManager = nil
        testContext = nil
        super.tearDown()
    }
    
    // MARK: - Contact CRUD Tests
    
    func testAddContact() {
        // Given
        let contact = Contact(
            firstName: "John",
            lastName: "Doe",
            email: "john@example.com",
            phoneNumber: "+1234567890"
        )
        
        // When
        contactManager.addContact(contact)
        
        // Then
        XCTAssertEqual(contactManager.contacts.count, 1)
        XCTAssertEqual(contactManager.contacts.first?.firstName, "John")
        XCTAssertEqual(contactManager.contacts.first?.lastName, "Doe")
        XCTAssertEqual(contactManager.contacts.first?.email, "john@example.com")
    }
    
    func testUpdateContact() {
        // Given
        var contact = Contact(
            firstName: "John",
            lastName: "Doe",
            email: "john@example.com"
        )
        contactManager.addContact(contact)
        
        // When
        contact.firstName = "Jane"
        contact.email = "jane@example.com"
        contactManager.updateContact(contact)
        
        // Then
        XCTAssertEqual(contactManager.contacts.count, 1)
        XCTAssertEqual(contactManager.contacts.first?.firstName, "Jane")
        XCTAssertEqual(contactManager.contacts.first?.email, "jane@example.com")
    }
    
    func testDeleteContact() {
        // Given
        let contact = Contact(
            firstName: "John",
            lastName: "Doe",
            email: "john@example.com"
        )
        contactManager.addContact(contact)
        XCTAssertEqual(contactManager.contacts.count, 1)
        
        // When
        contactManager.deleteContact(contact)
        
        // Then
        XCTAssertEqual(contactManager.contacts.count, 0)
    }
    
    func testToggleContactFavorite() {
        // Given
        let contact = Contact(
            firstName: "John",
            lastName: "Doe",
            email: "john@example.com"
        )
        contactManager.addContact(contact)
        XCTAssertFalse(contact.isFavorite)
        
        // When
        contactManager.toggleContactFavorite(contact)
        
        // Then
        XCTAssertTrue(contactManager.contacts.first?.isFavorite == true)
    }
    
    func testToggleContactBlocked() {
        // Given
        let contact = Contact(
            firstName: "John",
            lastName: "Doe",
            email: "john@example.com"
        )
        contactManager.addContact(contact)
        XCTAssertFalse(contact.isBlocked)
        
        // When
        contactManager.toggleContactBlocked(contact)
        
        // Then
        XCTAssertTrue(contactManager.contacts.first?.isBlocked == true)
    }
    
    // MARK: - Search and Filter Tests
    
    func testSearchContacts() {
        // Given
        let john = Contact(firstName: "John", lastName: "Doe", email: "john@example.com")
        let jane = Contact(firstName: "Jane", lastName: "Smith", email: "jane@test.com")
        let bob = Contact(firstName: "Bob", lastName: "Johnson", phoneNumber: "+1234567890")
        
        contactManager.addContact(john)
        contactManager.addContact(jane)
        contactManager.addContact(bob)
        
        // When & Then
        let johnResults = contactManager.searchContacts(query: "John")
        XCTAssertEqual(johnResults.count, 1)
        XCTAssertEqual(johnResults.first?.firstName, "John")
        
        let emailResults = contactManager.searchContacts(query: "example.com")
        XCTAssertEqual(emailResults.count, 1)
        XCTAssertEqual(emailResults.first?.email, "john@example.com")
        
        let phoneResults = contactManager.searchContacts(query: "1234")
        XCTAssertEqual(phoneResults.count, 1)
        XCTAssertEqual(phoneResults.first?.phoneNumber, "+1234567890")
    }
    
    func testGetContactsByGroup() {
        // Given
        var favoriteContact = Contact(firstName: "Favorite", lastName: "User", email: "fav@example.com")
        favoriteContact.isFavorite = true
        
        var blockedContact = Contact(firstName: "Blocked", lastName: "User", email: "blocked@example.com")
        blockedContact.isBlocked = true
        
        let regularContact = Contact(firstName: "Regular", lastName: "User", email: "regular@example.com")
        
        contactManager.addContact(favoriteContact)
        contactManager.addContact(blockedContact)
        contactManager.addContact(regularContact)
        
        // When & Then
        let favorites = contactManager.getContactsByGroup(ContactGroup.favoriteGroup)
        XCTAssertEqual(favorites.count, 1)
        XCTAssertEqual(favorites.first?.firstName, "Favorite")
        
        let blocked = contactManager.getContactsByGroup(ContactGroup.blockedGroup)
        XCTAssertEqual(blocked.count, 1)
        XCTAssertEqual(blocked.first?.firstName, "Blocked")
    }
    
    // MARK: - Contact Activity Tests
    
    func testAddContactActivity() {
        // Given
        let contact = Contact(firstName: "John", lastName: "Doe", email: "john@example.com")
        contactManager.addContact(contact)
        
        // When
        contactManager.addContactActivity(
            for: contact.id,
            type: .sifSent,
            sifId: "test-sif-123",
            notes: "Test SIF activity"
        )
        
        // Then
        let activities = contactManager.getContactActivities(for: contact.id)
        XCTAssertGreaterThan(activities.count, 0)
        
        let sifActivity = activities.first { $0.activityType == .sifSent }
        XCTAssertNotNil(sifActivity)
        XCTAssertEqual(sifActivity?.sifId, "test-sif-123")
        XCTAssertEqual(sifActivity?.notes, "Test SIF activity")
    }
    
    // MARK: - Contact Model Tests
    
    func testContactDisplayName() {
        // Test with first and last name
        let fullNameContact = Contact(firstName: "John", lastName: "Doe")
        XCTAssertEqual(fullNameContact.displayName, "John Doe")
        
        // Test with only first name
        let firstNameOnlyContact = Contact(firstName: "John", lastName: "")
        XCTAssertEqual(firstNameOnlyContact.displayName, "John")
        
        // Test with email fallback
        let emailOnlyContact = Contact(firstName: "", lastName: "", email: "test@example.com")
        XCTAssertEqual(emailOnlyContact.displayName, "test@example.com")
        
        // Test with phone fallback
        let phoneOnlyContact = Contact(firstName: "", lastName: "", phoneNumber: "+1234567890")
        XCTAssertEqual(phoneOnlyContact.displayName, "+1234567890")
    }
    
    func testContactInitials() {
        let contact = Contact(firstName: "John", lastName: "Doe")
        XCTAssertEqual(contact.initials, "JD")
        
        let singleNameContact = Contact(firstName: "John", lastName: "")
        XCTAssertEqual(singleNameContact.initials, "J")
        
        let noNameContact = Contact(firstName: "", lastName: "")
        XCTAssertEqual(noNameContact.initials, "")
    }
    
    // MARK: - Privacy Level Tests
    
    func testContactPrivacyLevels() {
        XCTAssertEqual(ContactPrivacyLevel.normal.displayName, "Normal")
        XCTAssertEqual(ContactPrivacyLevel.restricted.displayName, "Restricted")
        XCTAssertEqual(ContactPrivacyLevel.private_.displayName, "Private")
        
        XCTAssertEqual(ContactPrivacyLevel.normal.rawValue, 0)
        XCTAssertEqual(ContactPrivacyLevel.restricted.rawValue, 1)
        XCTAssertEqual(ContactPrivacyLevel.private_.rawValue, 2)
    }
    
    // MARK: - Contact Activity Type Tests
    
    func testContactActivityTypes() {
        XCTAssertEqual(ContactActivityType.sifSent.displayName, "SIF Sent")
        XCTAssertEqual(ContactActivityType.contactAdded.displayName, "Contact Added")
        XCTAssertEqual(ContactActivityType.contactBlocked.displayName, "Contact Blocked")
        
        XCTAssertEqual(ContactActivityType.sifSent.iconName, "arrow.up.circle")
        XCTAssertEqual(ContactActivityType.contactAdded.iconName, "person.badge.plus")
        XCTAssertEqual(ContactActivityType.contactBlocked.iconName, "person.crop.circle.badge.minus")
    }
}

// MARK: - Contact Group Tests
class ContactGroupTests: XCTestCase {
    
    func testSystemGroups() {
        let systemGroups = ContactGroup.allSystemGroups
        XCTAssertEqual(systemGroups.count, 3)
        
        let favoriteGroup = systemGroups.first { $0.name == "Favorites" }
        XCTAssertNotNil(favoriteGroup)
        XCTAssertTrue(favoriteGroup?.isSystemGroup == true)
        
        let recentGroup = systemGroups.first { $0.name == "Recent" }
        XCTAssertNotNil(recentGroup)
        XCTAssertTrue(recentGroup?.isSystemGroup == true)
        
        let blockedGroup = systemGroups.first { $0.name == "Blocked" }
        XCTAssertNotNil(blockedGroup)
        XCTAssertTrue(blockedGroup?.isSystemGroup == true)
    }
    
    func testContactGroupCreation() {
        let group = ContactGroup(name: "Family", colorHex: "#FF0000")
        XCTAssertEqual(group.name, "Family")
        XCTAssertEqual(group.colorHex, "#FF0000")
        XCTAssertFalse(group.isSystemGroup)
        XCTAssertNotNil(group.id)
    }
}