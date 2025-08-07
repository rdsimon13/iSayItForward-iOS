import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

// MARK: - SIFTimelineService
class SIFTimelineService: ObservableObject {
    private let db = Firestore.firestore()
    private var lastDocument: DocumentSnapshot?
    private var realtimeListener: ListenerRegistration?
    
    // Cache management
    private var cachedSIFs: [SIFItem] = []
    private let pageSize = 20
    
    // MARK: - Public Methods
    
    /// Fetch initial batch of SIFs for the timeline
    func fetchInitialSIFs() async throws -> [SIFItem] {
        let query = db.collection("sifs")
            .order(by: "createdDate", descending: true)
            .limit(to: pageSize)
        
        let snapshot = try await query.getDocuments()
        lastDocument = snapshot.documents.last
        
        let sifs = snapshot.documents.compactMap { document in
            try? document.data(as: SIFItem.self)
        }
        
        cachedSIFs = sifs
        return sifs
    }
    
    /// Fetch next page of SIFs for infinite scrolling
    func fetchNextPage() async throws -> [SIFItem] {
        guard let lastDoc = lastDocument else {
            return []
        }
        
        let query = db.collection("sifs")
            .order(by: "createdDate", descending: true)
            .start(afterDocument: lastDoc)
            .limit(to: pageSize)
        
        let snapshot = try await query.getDocuments()
        
        if !snapshot.documents.isEmpty {
            lastDocument = snapshot.documents.last
            
            let newSIFs = snapshot.documents.compactMap { document in
                try? document.data(as: SIFItem.self)
            }
            
            cachedSIFs.append(contentsOf: newSIFs)
            return newSIFs
        }
        
        return []
    }
    
    /// Refresh timeline data (pull-to-refresh)
    func refreshTimeline() async throws -> [SIFItem] {
        // Reset pagination
        lastDocument = nil
        cachedSIFs.removeAll()
        
        return try await fetchInitialSIFs()
    }
    
    /// Setup real-time listener for new SIFs
    func startRealtimeUpdates(completion: @escaping ([SIFItem]) -> Void) {
        // Stop any existing listener
        stopRealtimeUpdates()
        
        realtimeListener = db.collection("sifs")
            .order(by: "createdDate", descending: true)
            .limit(to: pageSize)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self,
                      let snapshot = snapshot,
                      error == nil else {
                    print("Error listening for real-time updates: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                let updatedSIFs = snapshot.documents.compactMap { document in
                    try? document.data(as: SIFItem.self)
                }
                
                // Update cache with latest data
                self.cachedSIFs = updatedSIFs
                completion(updatedSIFs)
            }
    }
    
    /// Stop real-time listener
    func stopRealtimeUpdates() {
        realtimeListener?.remove()
        realtimeListener = nil
    }
    
    /// Get cached SIFs for offline support
    func getCachedSIFs() -> [SIFItem] {
        return cachedSIFs
    }
    
    /// Check if more pages are available
    var hasMorePages: Bool {
        return lastDocument != nil
    }
    
    // MARK: - SIF Interaction Methods
    
    /// Toggle like status for a SIF
    func toggleLike(for sifId: String, currentLikes: [String]) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let sifRef = db.collection("sifs").document(sifId)
        var updatedLikes = currentLikes
        
        if updatedLikes.contains(uid) {
            updatedLikes.removeAll { $0 == uid }
        } else {
            updatedLikes.append(uid)
        }
        
        try await sifRef.updateData(["likes": updatedLikes])
    }
    
    /// Mark SIF as read
    func markAsRead(sifId: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let sifRef = db.collection("sifs").document(sifId)
        try await sifRef.updateData([
            "readBy": FieldValue.arrayUnion([uid])
        ])
    }
    
    deinit {
        stopRealtimeUpdates()
    }
}

// MARK: - Error Types
enum SIFTimelineError: Error, LocalizedError {
    case noMoreData
    case networkError
    case authenticationRequired
    
    var errorDescription: String? {
        switch self {
        case .noMoreData:
            return "No more messages to load"
        case .networkError:
            return "Network connection error"
        case .authenticationRequired:
            return "Authentication required"
        }
    }
}