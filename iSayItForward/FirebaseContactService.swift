import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

// MARK: - Firebase Contact Service
class FirebaseContactService: ObservableObject {
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    private let contactManager: ContactManager
    
    @Published var isSyncing = false
    @Published var syncError: Error?
    @Published var lastSyncDate: Date?
    
    init(contactManager: ContactManager) {
        self.contactManager = contactManager
        setupRealtimeListening()
    }
    
    // MARK: - Contact Synchronization
    
    func syncContactToFirebase(_ contact: Contact) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw ContactSyncError.notAuthenticated
        }
        
        isSyncing = true
        defer { isSyncing = false }
        
        let contactData = try contact.toFirebaseDocument()
        let documentRef = db.collection("users").document(uid).collection("contacts").document(contact.id.uuidString)
        
        try await documentRef.setData(contactData, merge: true)
        
        // Update local contact with Firebase ID if needed
        if contact.firebaseId == nil {
            var updatedContact = contact
            updatedContact.firebaseId = contact.id.uuidString
            contactManager.updateContact(updatedContact)
        }
        
        lastSyncDate = Date()
    }
    
    func syncContactFromFirebase(documentId: String) async throws -> Contact {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw ContactSyncError.notAuthenticated
        }
        
        let documentRef = db.collection("users").document(uid).collection("contacts").document(documentId)
        let document = try await documentRef.getDocument()
        
        guard document.exists, let data = document.data() else {
            throw ContactSyncError.documentNotFound
        }
        
        return try Contact.fromFirebaseDocument(data, documentId: documentId)
    }
    
    func deleteContactFromFirebase(_ contact: Contact) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw ContactSyncError.notAuthenticated
        }
        
        let documentRef = db.collection("users").document(uid).collection("contacts").document(contact.id.uuidString)
        try await documentRef.delete()
    }
    
    func syncAllContactsToFirebase() async {
        guard let uid = Auth.auth().currentUser?.uid else {
            syncError = ContactSyncError.notAuthenticated
            return
        }
        
        isSyncing = true
        defer { isSyncing = false }
        
        let contacts = contactManager.contacts
        let batch = db.batch()
        
        for contact in contacts {
            do {
                let contactData = try contact.toFirebaseDocument()
                let documentRef = db.collection("users").document(uid).collection("contacts").document(contact.id.uuidString)
                batch.setData(contactData, forDocument: documentRef, merge: true)
            } catch {
                print("Error preparing contact \(contact.displayName) for sync: \(error)")
            }
        }
        
        do {
            try await batch.commit()
            lastSyncDate = Date()
            print("Successfully synced \(contacts.count) contacts to Firebase")
        } catch {
            syncError = error
            print("Error syncing contacts to Firebase: \(error)")
        }
    }
    
    func syncAllContactsFromFirebase() async {
        guard let uid = Auth.auth().currentUser?.uid else {
            syncError = ContactSyncError.notAuthenticated
            return
        }
        
        isSyncing = true
        defer { isSyncing = false }
        
        do {
            let snapshot = try await db.collection("users").document(uid).collection("contacts").getDocuments()
            var syncedContacts: [Contact] = []
            
            for document in snapshot.documents {
                do {
                    let contact = try Contact.fromFirebaseDocument(document.data(), documentId: document.documentID)
                    syncedContacts.append(contact)
                } catch {
                    print("Error parsing contact from Firebase: \(error)")
                }
            }
            
            // Merge with local contacts
            await mergeContactsWithLocal(syncedContacts)
            lastSyncDate = Date()
            
        } catch {
            syncError = error
            print("Error syncing contacts from Firebase: \(error)")
        }
    }
    
    // MARK: - Real-time Listening
    
    private func setupRealtimeListening() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if let uid = user?.uid {
                self?.startListeningToContacts(uid: uid)
            } else {
                self?.stopListeningToContacts()
            }
        }
    }
    
    private var contactsListener: ListenerRegistration?
    
    private func startListeningToContacts(uid: String) {
        contactsListener = db.collection("users").document(uid).collection("contacts")
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    self?.syncError = error
                    return
                }
                
                self?.handleContactsSnapshot(snapshot)
            }
    }
    
    private func stopListeningToContacts() {
        contactsListener?.remove()
        contactsListener = nil
    }
    
    private func handleContactsSnapshot(_ snapshot: QuerySnapshot?) {
        guard let snapshot = snapshot else { return }
        
        Task {
            var updatedContacts: [Contact] = []
            
            for document in snapshot.documents {
                do {
                    let contact = try Contact.fromFirebaseDocument(document.data(), documentId: document.documentID)
                    updatedContacts.append(contact)
                } catch {
                    print("Error parsing real-time contact update: \(error)")
                }
            }
            
            await mergeContactsWithLocal(updatedContacts)
        }
    }
    
    // MARK: - Contact Groups Sync
    
    func syncContactGroupsToFirebase() async {
        guard let uid = Auth.auth().currentUser?.uid else {
            syncError = ContactSyncError.notAuthenticated
            return
        }
        
        let groups = contactManager.contactGroups.filter { !$0.isSystemGroup }
        
        for group in groups {
            do {
                let groupData = try group.toFirebaseDocument()
                let documentRef = db.collection("users").document(uid).collection("contactGroups").document(group.id.uuidString)
                try await documentRef.setData(groupData, merge: true)
            } catch {
                print("Error syncing group \(group.name): \(error)")
            }
        }
    }
    
    func syncContactGroupsFromFirebase() async {
        guard let uid = Auth.auth().currentUser?.uid else {
            syncError = ContactSyncError.notAuthenticated
            return
        }
        
        do {
            let snapshot = try await db.collection("users").document(uid).collection("contactGroups").getDocuments()
            
            for document in snapshot.documents {
                do {
                    let group = try ContactGroup.fromFirebaseDocument(document.data(), documentId: document.documentID)
                    
                    // Check if group already exists locally
                    if !contactManager.contactGroups.contains(where: { $0.id == group.id }) {
                        contactManager.addContactGroup(group)
                    }
                } catch {
                    print("Error parsing contact group from Firebase: \(error)")
                }
            }
        } catch {
            syncError = error
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func mergeContactsWithLocal(_ firebaseContacts: [Contact]) async {
        let localContacts = contactManager.contacts
        
        for firebaseContact in firebaseContacts {
            // Check if contact exists locally
            if let localContact = localContacts.first(where: { $0.id == firebaseContact.id || $0.firebaseId == firebaseContact.firebaseId }) {
                // Update if Firebase version is newer
                if firebaseContact.lastModifiedDate > localContact.lastModifiedDate {
                    contactManager.updateContact(firebaseContact)
                }
            } else {
                // Add new contact from Firebase
                contactManager.addContact(firebaseContact)
            }
        }
        
        // Handle deleted contacts (present locally but not in Firebase)
        for localContact in localContacts {
            if !firebaseContacts.contains(where: { $0.id == localContact.id }) {
                // Contact was deleted in Firebase, remove locally
                contactManager.deleteContact(localContact)
            }
        }
    }
    
    deinit {
        stopListeningToContacts()
    }
}

// MARK: - Firebase Document Extensions
extension Contact {
    func toFirebaseDocument() throws -> [String: Any] {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(self)
        guard let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ContactSyncError.encodingFailed
        }
        
        return jsonObject
    }
    
    static func fromFirebaseDocument(_ data: [String: Any], documentId: String) throws -> Contact {
        let jsonData = try JSONSerialization.data(withJSONObject: data)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        var contact = try decoder.decode(Contact.self, from: jsonData)
        contact.firebaseId = documentId
        return contact
    }
    
    var lastModifiedDate: Date {
        // Use the most recent activity date or created date
        return lastContactedDate ?? createdDate
    }
}

extension ContactGroup {
    func toFirebaseDocument() throws -> [String: Any] {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(self)
        guard let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ContactSyncError.encodingFailed
        }
        
        return jsonObject
    }
    
    static func fromFirebaseDocument(_ data: [String: Any], documentId: String) throws -> ContactGroup {
        let jsonData = try JSONSerialization.data(withJSONObject: data)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(ContactGroup.self, from: jsonData)
    }
}

// MARK: - Contact Sync Errors
enum ContactSyncError: LocalizedError {
    case notAuthenticated
    case encodingFailed
    case decodingFailed
    case documentNotFound
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User is not authenticated"
        case .encodingFailed:
            return "Failed to encode contact data"
        case .decodingFailed:
            return "Failed to decode contact data"
        case .documentNotFound:
            return "Contact document not found"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}