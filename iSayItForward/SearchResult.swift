import Foundation
import FirebaseFirestore

// MARK: - Search Result Types
enum SearchResultType: String, CaseIterable, Codable {
    case message = "message"
    case user = "user"
    case category = "category"
    case template = "template"
}

// MARK: - Generic Search Result Model
struct SearchResult: Identifiable, Codable, Hashable {
    let id: String
    let type: SearchResultType
    let title: String
    let subtitle: String?
    let description: String?
    let score: Double // Relevance score for ranking
    let lastModified: Date
    let metadata: [String: String]? // Additional context-specific data
    
    // For message results
    var messageId: String? {
        metadata?["messageId"]
    }
    
    var authorUid: String? {
        metadata?["authorUid"]
    }
    
    var scheduledDate: Date? {
        guard let dateString = metadata?["scheduledDate"] else { return nil }
        return ISO8601DateFormatter().date(from: dateString)
    }
    
    // For user results
    var userUid: String? {
        metadata?["userUid"]
    }
    
    var email: String? {
        metadata?["email"]
    }
    
    // For category/template results
    var categoryName: String? {
        metadata?["categoryName"]
    }
    
    var templateId: String? {
        metadata?["templateId"]
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(type)
    }
    
    static func == (lhs: SearchResult, rhs: SearchResult) -> Bool {
        lhs.id == rhs.id && lhs.type == rhs.type
    }
}

// MARK: - Search Result Factory
struct SearchResultFactory {
    
    static func createMessageResult(from sifItem: SIFItem, score: Double = 1.0) -> SearchResult {
        let metadata: [String: String] = [
            "messageId": sifItem.id ?? "",
            "authorUid": sifItem.authorUid,
            "scheduledDate": ISO8601DateFormatter().string(from: sifItem.scheduledDate)
        ]
        
        return SearchResult(
            id: sifItem.id ?? UUID().uuidString,
            type: .message,
            title: sifItem.subject,
            subtitle: "Scheduled for \(formatDate(sifItem.scheduledDate))",
            description: sifItem.message,
            score: score,
            lastModified: sifItem.createdDate,
            metadata: metadata
        )
    }
    
    static func createUserResult(from user: User, score: Double = 1.0) -> SearchResult {
        let metadata: [String: String] = [
            "userUid": user.uid,
            "email": user.email
        ]
        
        return SearchResult(
            id: user.uid,
            type: .user,
            title: user.name,
            subtitle: user.email,
            description: nil,
            score: score,
            lastModified: Date(),
            metadata: metadata
        )
    }
    
    static func createCategoryResult(name: String, description: String?, score: Double = 1.0) -> SearchResult {
        let metadata: [String: String] = [
            "categoryName": name
        ]
        
        return SearchResult(
            id: name,
            type: .category,
            title: name,
            subtitle: "Category",
            description: description,
            score: score,
            lastModified: Date(),
            metadata: metadata
        )
    }
    
    static func createTemplateResult(from template: TemplateItem, score: Double = 1.0) -> SearchResult {
        let metadata: [String: String] = [
            "templateId": template.id.uuidString,
            "categoryName": template.category.rawValue
        ]
        
        return SearchResult(
            id: template.id.uuidString,
            type: .template,
            title: template.name,
            subtitle: template.category.rawValue,
            description: template.message,
            score: score,
            lastModified: Date(),
            metadata: metadata
        )
    }
    
    private static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}