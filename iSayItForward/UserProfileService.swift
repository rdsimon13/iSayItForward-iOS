import Foundation
import FirebaseAuth
import FirebaseFirestore

// Service class for handling user profile operations
class UserProfileService: ObservableObject {
    private let db = Firestore.firestore()
    private var cache: [String: UserProfile] = [:]
    
    // MARK: - Profile Data Fetching
    
    /// Fetch a user's profile data by their UID
    func fetchUserProfile(uid: String) async throws -> UserProfile {
        // Check cache first
        if let cachedProfile = cache[uid] {
            return cachedProfile
        }
        
        // Handle demo/sample users for testing
        if SampleDataUtility.isDemoUser(uid) {
            let profile = SampleDataUtility.sampleUsers.first { $0.uid == uid }!
            cache[uid] = profile
            return profile
        }
        
        let document = try await db.collection("users").document(uid).getDocument()
        
        guard document.exists, let data = document.data() else {
            throw ProfileServiceError.userNotFound
        }
        
        let profile = UserProfile(
            uid: uid,
            name: data["name"] as? String ?? "Unknown User",
            email: data["email"] as? String ?? "",
            bio: data["bio"] as? String,
            profileImageURL: data["profileImageURL"] as? String,
            joinDate: (data["joinDate"] as? Timestamp)?.dateValue() ?? Date(),
            followersCount: data["followersCount"] as? Int ?? 0,
            followingCount: data["followingCount"] as? Int ?? 0,
            sifsSharedCount: data["sifsSharedCount"] as? Int ?? 0,
            totalImpactScore: data["totalImpactScore"] as? Int ?? 0
        )
        
        // Cache the profile
        cache[uid] = profile
        return profile
    }
    
    /// Fetch messages/SIFs created by a specific user
    func fetchUserMessages(uid: String, limit: Int = 20, lastDocument: DocumentSnapshot? = nil) async throws -> (messages: [SIFItem], lastDocument: DocumentSnapshot?) {
        // Handle demo/sample users for testing
        if SampleDataUtility.isDemoUser(uid) {
            let messages = SampleDataUtility.sampleMessages(for: uid)
            return (messages: messages, lastDocument: nil)
        }
        
        var query = db.collection("sifs")
            .whereField("authorUid", isEqualTo: uid)
            .whereField("isPublic", isEqualTo: true) // Only fetch public messages
            .order(by: "createdDate", descending: true)
            .limit(to: limit)
        
        if let lastDocument = lastDocument {
            query = query.start(afterDocument: lastDocument)
        }
        
        let snapshot = try await query.getDocuments()
        
        let messages = snapshot.documents.compactMap { doc -> SIFItem? in
            try? doc.data(as: SIFItem.self)
        }
        
        return (messages: messages, lastDocument: snapshot.documents.last)
    }
    
    // MARK: - Follow Operations
    
    /// Check if current user follows the specified user
    func checkFollowStatus(targetUID: String) async throws -> Bool {
        guard let currentUID = Auth.auth().currentUser?.uid else {
            throw ProfileServiceError.notAuthenticated
        }
        
        // Handle demo users - simulate follow status
        if SampleDataUtility.isDemoUser(targetUID) {
            return false // Default to not following for demo
        }
        
        let document = try await db.collection("follows")
            .document("\(currentUID)_\(targetUID)")
            .getDocument()
        
        return document.exists
    }
    
    /// Follow or unfollow a user
    func toggleFollow(targetUID: String) async throws -> Bool {
        guard let currentUID = Auth.auth().currentUser?.uid else {
            throw ProfileServiceError.notAuthenticated
        }
        
        guard currentUID != targetUID else {
            throw ProfileServiceError.cannotFollowSelf
        }
        
        let followDocRef = db.collection("follows").document("\(currentUID)_\(targetUID)")
        let currentUserRef = db.collection("users").document(currentUID)
        let targetUserRef = db.collection("users").document(targetUID)
        
        let isFollowing = try await checkFollowStatus(targetUID: targetUID)
        
        try await db.runTransaction { transaction, errorPointer in
            if isFollowing {
                // Unfollow
                transaction.deleteDocument(followDocRef)
                transaction.updateData(["followingCount": FieldValue.increment(Int64(-1))], forDocument: currentUserRef)
                transaction.updateData(["followersCount": FieldValue.increment(Int64(-1))], forDocument: targetUserRef)
            } else {
                // Follow
                transaction.setData([
                    "followerUID": currentUID,
                    "followingUID": targetUID,
                    "createdDate": FieldValue.serverTimestamp()
                ], forDocument: followDocRef)
                transaction.updateData(["followingCount": FieldValue.increment(Int64(1))], forDocument: currentUserRef)
                transaction.updateData(["followersCount": FieldValue.increment(Int64(1))], forDocument: targetUserRef)
            }
            return nil
        }
        
        // Clear cache to force refresh
        cache.removeValue(forKey: targetUID)
        
        return !isFollowing // Return new follow status
    }
    
    // MARK: - Report User
    
    /// Report a user for inappropriate behavior
    func reportUser(targetUID: String, reason: String, details: String? = nil) async throws {
        guard let currentUID = Auth.auth().currentUser?.uid else {
            throw ProfileServiceError.notAuthenticated
        }
        
        guard currentUID != targetUID else {
            throw ProfileServiceError.cannotReportSelf
        }
        
        try await db.collection("reports").addDocument(data: [
            "reporterUID": currentUID,
            "reportedUID": targetUID,
            "reason": reason,
            "details": details ?? "",
            "createdDate": FieldValue.serverTimestamp(),
            "status": "pending"
        ])
    }
    
    // MARK: - Analytics Tracking
    
    /// Track profile view for analytics
    func trackProfileView(profileUID: String) {
        guard let currentUID = Auth.auth().currentUser?.uid else { return }
        
        // Don't track views of own profile
        guard currentUID != profileUID else { return }
        
        Task {
            try await db.collection("analytics").addDocument(data: [
                "event": "profile_view",
                "viewerUID": currentUID,
                "profileUID": profileUID,
                "timestamp": FieldValue.serverTimestamp()
            ])
        }
    }
    
    // MARK: - Cache Management
    
    /// Clear the profile cache
    func clearCache() {
        cache.removeAll()
    }
    
    /// Remove specific profile from cache
    func removeCachedProfile(uid: String) {
        cache.removeValue(forKey: uid)
    }
}

// MARK: - Data Models

struct UserProfile: Identifiable, Codable {
    let uid: String
    let name: String
    let email: String
    let bio: String?
    let profileImageURL: String?
    let joinDate: Date
    let followersCount: Int
    let followingCount: Int
    let sifsSharedCount: Int
    let totalImpactScore: Int
    
    var id: String { uid }
    
    // Computed properties for display
    var initials: String {
        let components = name.components(separatedBy: " ")
        let firstInitial = components.first?.first?.uppercased() ?? ""
        let lastInitial = components.count > 1 ? components.last?.first?.uppercased() ?? "" : ""
        return firstInitial + lastInitial
    }
    
    var memberSince: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return "Member since \(formatter.string(from: joinDate))"
    }
}

// MARK: - Error Types

enum ProfileServiceError: LocalizedError {
    case userNotFound
    case notAuthenticated
    case cannotFollowSelf
    case cannotReportSelf
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User profile not found"
        case .notAuthenticated:
            return "You must be logged in to perform this action"
        case .cannotFollowSelf:
            return "You cannot follow yourself"
        case .cannotReportSelf:
            return "You cannot report yourself"
        case .networkError:
            return "Network error occurred"
        }
    }
}