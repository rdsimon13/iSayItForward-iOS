import Foundation
import FirebaseFirestore

struct Category: Identifiable, Codable, Hashable, Equatable {
    @DocumentID var id: String?
    
    let name: String
    let description: String
    let iconName: String
    let colorHex: String
    let isSystem: Bool // System categories vs user-created
    let parentCategoryId: String? // For hierarchical categories
    let createdDate: Date
    let createdBy: String? // User ID who created this category
    
    // Usage statistics
    var messageCount: Int = 0
    var subscriberCount: Int = 0
    var lastUsedDate: Date?
    
    // Display properties
    var isActive: Bool = true
    var sortOrder: Int = 0
    
    // Hashable & Equatable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Category, rhs: Category) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Category Extensions
extension Category {
    var displayName: String {
        name.capitalized
    }
    
    var hasParent: Bool {
        parentCategoryId != nil
    }
    
    static var systemCategories: [Category] {
        [
            Category(
                id: nil,
                name: "encouragement",
                description: "Uplifting and motivational messages",
                iconName: "heart.fill",
                colorHex: "#FF6B6B",
                isSystem: true,
                parentCategoryId: nil,
                createdDate: Date(),
                createdBy: nil,
                messageCount: 0,
                subscriberCount: 0,
                lastUsedDate: nil,
                isActive: true,
                sortOrder: 1
            ),
            Category(
                id: nil,
                name: "celebration",
                description: "Birthday, anniversary, and achievement messages",
                iconName: "party.popper.fill",
                colorHex: "#4ECDC4",
                isSystem: true,
                parentCategoryId: nil,
                createdDate: Date(),
                createdBy: nil,
                messageCount: 0,
                subscriberCount: 0,
                lastUsedDate: nil,
                isActive: true,
                sortOrder: 2
            ),
            Category(
                id: nil,
                name: "sympathy",
                description: "Condolences and support messages",
                iconName: "hands.sparkles.fill",
                colorHex: "#95A5A6",
                isSystem: true,
                parentCategoryId: nil,
                createdDate: Date(),
                createdBy: nil,
                messageCount: 0,
                subscriberCount: 0,
                lastUsedDate: nil,
                isActive: true,
                sortOrder: 3
            ),
            Category(
                id: nil,
                name: "announcement",
                description: "News, updates, and important information",
                iconName: "megaphone.fill",
                colorHex: "#F39C12",
                isSystem: true,
                parentCategoryId: nil,
                createdDate: Date(),
                createdBy: nil,
                messageCount: 0,
                subscriberCount: 0,
                lastUsedDate: nil,
                isActive: true,
                sortOrder: 4
            ),
            Category(
                id: nil,
                name: "holiday",
                description: "Seasonal and holiday greetings",
                iconName: "gift.fill",
                colorHex: "#E74C3C",
                isSystem: true,
                parentCategoryId: nil,
                createdDate: Date(),
                createdBy: nil,
                messageCount: 0,
                subscriberCount: 0,
                lastUsedDate: nil,
                isActive: true,
                sortOrder: 5
            ),
            Category(
                id: nil,
                name: "gratitude",
                description: "Thank you and appreciation messages",
                iconName: "hand.raised.fill",
                colorHex: "#27AE60",
                isSystem: true,
                parentCategoryId: nil,
                createdDate: Date(),
                createdBy: nil,
                messageCount: 0,
                subscriberCount: 0,
                lastUsedDate: nil,
                isActive: true,
                sortOrder: 6
            )
        ]
    }
    
    // MARK: - Convenience Initializers
    init(
        name: String,
        description: String,
        iconName: String,
        colorHex: String,
        isSystem: Bool = false,
        parentCategoryId: String? = nil,
        createdBy: String? = nil
    ) {
        self.id = nil
        self.name = name
        self.description = description
        self.iconName = iconName
        self.colorHex = colorHex
        self.isSystem = isSystem
        self.parentCategoryId = parentCategoryId
        self.createdDate = Date()
        self.createdBy = createdBy
        self.messageCount = 0
        self.subscriberCount = 0
        self.lastUsedDate = nil
        self.isActive = true
        self.sortOrder = 0
    }
}