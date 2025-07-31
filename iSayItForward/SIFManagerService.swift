import Foundation
import FirebaseFirestore
import FirebaseAuth

// Service responsible for SIF folder management, search, and organization
class SIFManagerService: ObservableObject {
    static let shared = SIFManagerService()
    
    @Published var sentSIFs: [SIFItem] = []
    @Published var receivedSIFs: [SIFItem] = []
    @Published var favoriteSIFs: [SIFItem] = []
    @Published var archivedSIFs: [SIFItem] = []
    @Published var folders: [SIFFolder] = []
    @Published var searchResults: [SIFItem] = []
    @Published var isLoading = false
    
    private let db = Firestore.firestore()
    private var listeners: [ListenerRegistration] = []
    
    // Default folders
    private let defaultFolders = [
        SIFFolder(id: "sent", name: "Sent", icon: "paperplane", color: "blue"),
        SIFFolder(id: "received", name: "Received", icon: "tray", color: "green"),
        SIFFolder(id: "drafts", name: "Drafts", icon: "doc.text", color: "orange"),
        SIFFolder(id: "favorites", name: "Favorites", icon: "heart.fill", color: "red"),
        SIFFolder(id: "archived", name: "Archived", icon: "archivebox", color: "gray"),
        SIFFolder(id: "scheduled", name: "Scheduled", icon: "calendar", color: "purple")
    ]
    
    private init() {
        setupDefaultFolders()
    }
    
    deinit {
        removeAllListeners()
    }
    
    // MARK: - Folder Management
    
    func setupDefaultFolders() {
        folders = defaultFolders
    }
    
    func createCustomFolder(name: String, icon: String = "folder", color: String = "blue") async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw SIFManagerError.authenticationRequired
        }
        
        let folderId = UUID().uuidString
        let folder = SIFFolder(id: folderId, name: name, icon: icon, color: color, isCustom: true)
        
        try await db.collection("users").document(userId).collection("folders").document(folderId).setData([
            "name": name,
            "icon": icon,
            "color": color,
            "isCustom": true,
            "createdDate": Date()
        ])
        
        DispatchQueue.main.async {
            self.folders.append(folder)
        }
    }
    
    func deleteCustomFolder(folderId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw SIFManagerError.authenticationRequired
        }
        
        // Move all SIFs from this folder to "Sent"
        try await moveSIFsFromFolder(folderId: folderId, toFolder: "sent")
        
        // Delete the folder
        try await db.collection("users").document(userId).collection("folders").document(folderId).delete()
        
        DispatchQueue.main.async {
            self.folders.removeAll { $0.id == folderId }
        }
    }
    
    private func moveSIFsFromFolder(folderId: String, toFolder: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let snapshot = try await db.collection("sifs")
            .whereField("authorUid", isEqualTo: userId)
            .whereField("folderPath", isEqualTo: folderId)
            .getDocuments()
        
        for document in snapshot.documents {
            try await document.reference.updateData(["folderPath": toFolder])
        }
    }
    
    // MARK: - SIF Management
    
    func fetchSIFs() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        DispatchQueue.main.async {
            self.isLoading = true
        }
        
        do {
            // Fetch sent SIFs
            let sentSnapshot = try await db.collection("sifs")
                .whereField("authorUid", isEqualTo: userId)
                .order(by: "createdDate", descending: true)
                .getDocuments()
            
            let sent = sentSnapshot.documents.compactMap { doc -> SIFItem? in
                try? doc.data(as: SIFItem.self)
            }
            
            // Fetch received SIFs (where user is in recipients)
            let receivedSnapshot = try await db.collection("sifs")
                .whereField("recipients", arrayContains: userId)
                .order(by: "createdDate", descending: true)
                .getDocuments()
            
            let received = receivedSnapshot.documents.compactMap { doc -> SIFItem? in
                try? doc.data(as: SIFItem.self)
            }
            
            DispatchQueue.main.async {
                self.sentSIFs = sent
                self.receivedSIFs = received
                self.favoriteSIFs = sent.filter { $0.isFavorite } + received.filter { $0.isFavorite }
                self.archivedSIFs = sent.filter { $0.isArchived } + received.filter { $0.isArchived }
                self.isLoading = false
            }
            
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
            }
            print("Error fetching SIFs: \(error)")
        }
    }
    
    func getSIFsInFolder(_ folderId: String) -> [SIFItem] {
        switch folderId {
        case "sent":
            return sentSIFs.filter { !$0.isArchived }
        case "received":
            return receivedSIFs.filter { !$0.isArchived }
        case "favorites":
            return favoriteSIFs
        case "archived":
            return archivedSIFs
        case "scheduled":
            return sentSIFs.filter { $0.deliveryStatus == .scheduled }
        case "drafts":
            return sentSIFs.filter { $0.deliveryStatus == .pending }
        default:
            return (sentSIFs + receivedSIFs).filter { $0.folderPath == folderId }
        }
    }
    
    func moveSIFToFolder(sifId: String, folderId: String) async throws {
        try await db.collection("sifs").document(sifId).updateData([
            "folderPath": folderId
        ])
        
        await fetchSIFs() // Refresh data
    }
    
    func toggleFavorite(sifId: String) async throws {
        let docRef = db.collection("sifs").document(sifId)
        let document = try await docRef.getDocument()
        
        if let sif = try? document.data(as: SIFItem.self) {
            try await docRef.updateData([
                "isFavorite": !sif.isFavorite
            ])
            
            await fetchSIFs() // Refresh data
        }
    }
    
    func toggleArchive(sifId: String) async throws {
        let docRef = db.collection("sifs").document(sifId)
        let document = try await docRef.getDocument()
        
        if let sif = try? document.data(as: SIFItem.self) {
            try await docRef.updateData([
                "isArchived": !sif.isArchived
            ])
            
            await fetchSIFs() // Refresh data
        }
    }
    
    func addTagsToSIF(sifId: String, tags: [String]) async throws {
        let docRef = db.collection("sifs").document(sifId)
        let document = try await docRef.getDocument()
        
        if let sif = try? document.data(as: SIFItem.self) {
            let newTags = Array(Set(sif.tags + tags)) // Remove duplicates
            try await docRef.updateData([
                "tags": newTags
            ])
        }
    }
    
    func removeTagFromSIF(sifId: String, tag: String) async throws {
        let docRef = db.collection("sifs").document(sifId)
        let document = try await docRef.getDocument()
        
        if let sif = try? document.data(as: SIFItem.self) {
            let newTags = sif.tags.filter { $0 != tag }
            try await docRef.updateData([
                "tags": newTags
            ])
        }
    }
    
    // MARK: - Search and Filter
    
    func searchSIFs(query: String, filters: SIFSearchFilters = SIFSearchFilters()) async {
        guard !query.isEmpty else {
            DispatchQueue.main.async {
                self.searchResults = []
            }
            return
        }
        
        let allSIFs = sentSIFs + receivedSIFs
        let lowercaseQuery = query.lowercased()
        
        let results = allSIFs.filter { sif in
            let matchesQuery = sif.subject.lowercased().contains(lowercaseQuery) ||
                             sif.message.lowercased().contains(lowercaseQuery) ||
                             sif.recipients.joined().lowercased().contains(lowercaseQuery) ||
                             sif.tags.joined().lowercased().contains(lowercaseQuery)
            
            let matchesStatus = filters.statuses.isEmpty || filters.statuses.contains(sif.deliveryStatus)
            let matchesDateRange = filters.isInDateRange(sif.createdDate)
            let matchesTags = filters.tags.isEmpty || !Set(sif.tags).isDisjoint(with: Set(filters.tags))
            let matchesAttachments = !filters.hasAttachmentsOnly || !sif.attachmentURLs.isEmpty
            
            return matchesQuery && matchesStatus && matchesDateRange && matchesTags && matchesAttachments
        }
        
        DispatchQueue.main.async {
            self.searchResults = results
        }
    }
    
    func sortSIFs(_ sifs: [SIFItem], by sortOption: SIFSortOption) -> [SIFItem] {
        switch sortOption {
        case .dateCreated:
            return sifs.sorted { $0.createdDate > $1.createdDate }
        case .dateScheduled:
            return sifs.sorted { $0.scheduledDate > $1.scheduledDate }
        case .subject:
            return sifs.sorted { $0.subject.localizedCaseInsensitiveCompare($1.subject) == .orderedAscending }
        case .status:
            return sifs.sorted { $0.deliveryStatus.rawValue < $1.deliveryStatus.rawValue }
        case .size:
            return sifs.sorted { $0.totalAttachmentSize > $1.totalAttachmentSize }
        case .recipients:
            return sifs.sorted { $0.recipients.count > $1.recipients.count }
        }
    }
    
    // MARK: - Batch Operations
    
    func performBatchOperation(_ operation: SIFBatchOperation, on sifIds: [String]) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw SIFManagerError.authenticationRequired
        }
        
        switch operation {
        case .delete:
            try await batchDeleteSIFs(sifIds)
        case .archive:
            try await batchUpdateSIFs(sifIds, updates: ["isArchived": true])
        case .unarchive:
            try await batchUpdateSIFs(sifIds, updates: ["isArchived": false])
        case .favorite:
            try await batchUpdateSIFs(sifIds, updates: ["isFavorite": true])
        case .unfavorite:
            try await batchUpdateSIFs(sifIds, updates: ["isFavorite": false])
        case .moveToFolder(let folderId):
            try await batchUpdateSIFs(sifIds, updates: ["folderPath": folderId])
        case .addTags(let tags):
            try await batchAddTags(sifIds, tags: tags)
        case .removeTags(let tags):
            try await batchRemoveTags(sifIds, tags: tags)
        }
        
        await fetchSIFs() // Refresh data
    }
    
    private func batchDeleteSIFs(_ sifIds: [String]) async throws {
        let batch = db.batch()
        
        for sifId in sifIds {
            let docRef = db.collection("sifs").document(sifId)
            batch.deleteDocument(docRef)
        }
        
        try await batch.commit()
    }
    
    private func batchUpdateSIFs(_ sifIds: [String], updates: [String: Any]) async throws {
        let batch = db.batch()
        
        for sifId in sifIds {
            let docRef = db.collection("sifs").document(sifId)
            batch.updateData(updates, forDocument: docRef)
        }
        
        try await batch.commit()
    }
    
    private func batchAddTags(_ sifIds: [String], tags: [String]) async throws {
        for sifId in sifIds {
            try await addTagsToSIF(sifId: sifId, tags: tags)
        }
    }
    
    private func batchRemoveTags(_ sifIds: [String], tags: [String]) async throws {
        for sifId in sifIds {
            for tag in tags {
                try await removeTagFromSIF(sifId: sifId, tag: tag)
            }
        }
    }
    
    // MARK: - Real-time Updates
    
    func startListening() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Listen to sent SIFs
        let sentListener = db.collection("sifs")
            .whereField("authorUid", isEqualTo: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Error listening to sent SIFs: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                let sifs = documents.compactMap { try? $0.data(as: SIFItem.self) }
                
                DispatchQueue.main.async {
                    self?.sentSIFs = sifs
                    self?.updateDerivedCollections()
                }
            }
        
        // Listen to received SIFs
        let receivedListener = db.collection("sifs")
            .whereField("recipients", arrayContains: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Error listening to received SIFs: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                let sifs = documents.compactMap { try? $0.data(as: SIFItem.self) }
                
                DispatchQueue.main.async {
                    self?.receivedSIFs = sifs
                    self?.updateDerivedCollections()
                }
            }
        
        listeners = [sentListener, receivedListener]
    }
    
    func removeAllListeners() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
    }
    
    private func updateDerivedCollections() {
        favoriteSIFs = (sentSIFs + receivedSIFs).filter { $0.isFavorite }
        archivedSIFs = (sentSIFs + receivedSIFs).filter { $0.isArchived }
    }
}

// MARK: - Supporting Models

struct SIFFolder: Identifiable, Codable {
    let id: String
    let name: String
    let icon: String
    let color: String
    let isCustom: Bool
    let createdDate: Date
    
    init(id: String, name: String, icon: String, color: String, isCustom: Bool = false) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
        self.isCustom = isCustom
        self.createdDate = Date()
    }
}

struct SIFSearchFilters {
    var statuses: [SIFDeliveryStatus] = []
    var tags: [String] = []
    var dateFrom: Date?
    var dateTo: Date?
    var hasAttachmentsOnly: Bool = false
    
    func isInDateRange(_ date: Date) -> Bool {
        if let from = dateFrom, date < from { return false }
        if let to = dateTo, date > to { return false }
        return true
    }
}

enum SIFSortOption: String, CaseIterable {
    case dateCreated = "Date Created"
    case dateScheduled = "Date Scheduled"
    case subject = "Subject"
    case status = "Status"
    case size = "Size"
    case recipients = "Recipients"
}

enum SIFBatchOperation {
    case delete
    case archive
    case unarchive
    case favorite
    case unfavorite
    case moveToFolder(String)
    case addTags([String])
    case removeTags([String])
}

enum SIFManagerError: LocalizedError {
    case authenticationRequired
    case folderNotFound
    case invalidOperation
    
    var errorDescription: String? {
        switch self {
        case .authenticationRequired:
            return "User authentication required"
        case .folderNotFound:
            return "Folder not found"
        case .invalidOperation:
            return "Invalid operation"
        }
    }
}