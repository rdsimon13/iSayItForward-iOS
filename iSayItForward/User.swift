import Foundation

// This struct defines the data we will store for each user
// in our Firestore database.
struct User: Codable {
    let uid: String
    let name: String
    let email: String
    let tier: UserTier
    let tierExpiryDate: Date?
    let createdAt: Date
    let lastUpdated: Date
    
    // Computed properties for convenience
    var isSubscriptionActive: Bool {
        guard let expiryDate = tierExpiryDate else {
            return tier == .free // Free tier never expires
        }
        return Date() < expiryDate
    }
    
    var effectiveTier: UserTier {
        return isSubscriptionActive ? tier : .free
    }
    
    // Initialize with default values
    init(uid: String, name: String, email: String, tier: UserTier = .free) {
        self.uid = uid
        self.name = name
        self.email = email
        self.tier = tier
        self.tierExpiryDate = tier == .free ? nil : Calendar.current.date(byAdding: .month, value: 1, to: Date())
        self.createdAt = Date()
        self.lastUpdated = Date()
    }
    
    // Initialize from Firestore data
    init?(from data: [String: Any]) {
        guard let uid = data["uid"] as? String,
              let name = data["name"] as? String,
              let email = data["email"] as? String else {
            return nil
        }
        
        self.uid = uid
        self.name = name
        self.email = email
        
        // Handle tier with fallback to free
        if let tierString = data["tier"] as? String,
           let tier = UserTier(rawValue: tierString) {
            self.tier = tier
        } else {
            self.tier = .free
        }
        
        // Handle dates
        if let expiryTimestamp = data["tierExpiryDate"] as? Double {
            self.tierExpiryDate = Date(timeIntervalSince1970: expiryTimestamp)
        } else {
            self.tierExpiryDate = nil
        }
        
        if let createdTimestamp = data["createdAt"] as? Double {
            self.createdAt = Date(timeIntervalSince1970: createdTimestamp)
        } else {
            self.createdAt = Date()
        }
        
        if let updatedTimestamp = data["lastUpdated"] as? Double {
            self.lastUpdated = Date(timeIntervalSince1970: updatedTimestamp)
        } else {
            self.lastUpdated = Date()
        }
    }
    
    // Convert to Firestore data
    func toFirestoreData() -> [String: Any] {
        var data: [String: Any] = [
            "uid": uid,
            "name": name,
            "email": email,
            "tier": tier.rawValue,
            "createdAt": createdAt.timeIntervalSince1970,
            "lastUpdated": lastUpdated.timeIntervalSince1970
        ]
        
        if let expiryDate = tierExpiryDate {
            data["tierExpiryDate"] = expiryDate.timeIntervalSince1970
        }
        
        return data
    }
}
