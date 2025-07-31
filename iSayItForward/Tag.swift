import Foundation
import FirebaseFirestore

struct Tag: Identifiable, Codable, Hashable, Equatable {
    @DocumentID var id: String?
    
    let name: String
    let normalizedName: String // Lowercase, no spaces for searching
    let createdDate: Date
    let createdBy: String? // User ID who created this tag
    
    // Usage statistics
    var usageCount: Int = 0
    var lastUsedDate: Date?
    var trendingScore: Double = 0.0
    
    // Properties
    var isVerified: Bool = false // Verified tags by moderators
    var isBlocked: Bool = false // Blocked inappropriate tags
    var relatedTags: [String] = [] // Related tag names
    
    // Hashable & Equatable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Tag, rhs: Tag) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Tag Extensions
extension Tag {
    var displayName: String {
        "#\(name)"
    }
    
    var isPopular: Bool {
        usageCount >= 100
    }
    
    var isTrending: Bool {
        trendingScore > 0.7
    }
    
    static func normalize(_ name: String) -> String {
        name.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "#", with: "")
    }
    
    static func isValid(_ name: String) -> Bool {
        let normalizedName = normalize(name)
        return normalizedName.count >= 2 && 
               normalizedName.count <= 30 &&
               normalizedName.allSatisfy { $0.isLetter || $0.isNumber }
    }
    
    init(name: String, createdBy: String?) {
        self.id = nil
        self.name = name
        self.normalizedName = Tag.normalize(name)
        self.createdDate = Date()
        self.createdBy = createdBy
        self.usageCount = 1
        self.lastUsedDate = Date()
        self.trendingScore = 0.0
        self.isVerified = false
        self.isBlocked = false
        self.relatedTags = []
    }
}