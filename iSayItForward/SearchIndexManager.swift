import Foundation
import FirebaseFirestore

// MARK: - Search Index Manager
class SearchIndexManager: ObservableObject {
    @Published var isIndexing = false
    @Published var indexingProgress = 0.0
    @Published var lastIndexUpdate: Date?
    
    private let db = Firestore.firestore()
    private let indexCollection = "search_index"
    
    // MARK: - Index Management
    func buildIndex() async {
        await MainActor.run {
            isIndexing = true
            indexingProgress = 0.0
        }
        
        do {
            // Index messages
            await updateProgress(0.1)
            try await indexMessages()
            
            // Index users
            await updateProgress(0.3)
            try await indexUsers()
            
            // Index templates
            await updateProgress(0.6)
            try await indexTemplates()
            
            // Index categories
            await updateProgress(0.8)
            try await indexCategories()
            
            // Finalize
            await updateProgress(1.0)
            await updateLastIndexTime()
            
        } catch {
            print("Error building search index: \(error)")
        }
        
        await MainActor.run {
            isIndexing = false
        }
    }
    
    func updateIndex(for contentType: SearchResultType, contentId: String, content: [String: Any]) async {
        do {
            let indexEntry = createIndexEntry(
                contentType: contentType,
                contentId: contentId,
                content: content
            )
            
            try await db.collection(indexCollection)
                .document(indexEntry.id)
                .setData(from: indexEntry)
                
        } catch {
            print("Error updating index: \(error)")
        }
    }
    
    func removeFromIndex(contentType: SearchResultType, contentId: String) async {
        let indexId = "\(contentType.rawValue)_\(contentId)"
        
        do {
            try await db.collection(indexCollection)
                .document(indexId)
                .delete()
        } catch {
            print("Error removing from index: \(error)")
        }
    }
    
    // MARK: - Index Search
    func searchIndex(query: String, contentTypes: [SearchResultType] = SearchResultType.allCases) async throws -> [SearchIndexEntry] {
        let queryWords = query.lowercased().components(separatedBy: .whitespacesAndPunctuation).filter { !$0.isEmpty }
        
        // Build compound query
        var firestoreQuery: Query = db.collection(indexCollection)
        
        if !contentTypes.isEmpty {
            firestoreQuery = firestoreQuery.whereField("contentType", in: contentTypes.map(\.rawValue))
        }
        
        let snapshot = try await firestoreQuery.getDocuments()
        
        let entries = snapshot.documents.compactMap { document -> SearchIndexEntry? in
            try? document.data(as: SearchIndexEntry.self)
        }
        
        // Filter and score results
        let scoredEntries = entries.compactMap { entry -> (entry: SearchIndexEntry, score: Double)? in
            let score = calculateIndexScore(entry: entry, queryWords: queryWords)
            return score > 0 ? (entry, score) : nil
        }
        
        // Sort by score and return
        return scoredEntries
            .sorted { $0.score > $1.score }
            .map { $0.entry }
    }
    
    // MARK: - Private Indexing Methods
    private func indexMessages() async throws {
        let snapshot = try await db.collection("sifs").getDocuments()
        
        for document in snapshot.documents {
            guard let sifItem = try? document.data(as: SIFItem.self),
                  let id = sifItem.id else { continue }
            
            let content: [String: Any] = [
                "subject": sifItem.subject,
                "message": sifItem.message,
                "authorUid": sifItem.authorUid,
                "createdDate": sifItem.createdDate,
                "scheduledDate": sifItem.scheduledDate
            ]
            
            await updateIndex(for: .message, contentId: id, content: content)
        }
    }
    
    private func indexUsers() async throws {
        let snapshot = try await db.collection("users").getDocuments()
        
        for document in snapshot.documents {
            guard let userData = document.data() as? [String: Any],
                  let uid = userData["uid"] as? String,
                  let name = userData["name"] as? String,
                  let email = userData["email"] as? String else { continue }
            
            let content: [String: Any] = [
                "name": name,
                "email": email,
                "uid": uid
            ]
            
            await updateIndex(for: .user, contentId: uid, content: content)
        }
    }
    
    private func indexTemplates() async throws {
        let templates = TemplateLibrary.allTemplates
        
        for template in templates {
            let content: [String: Any] = [
                "title": template.title,
                "content": template.content,
                "category": template.category.rawValue
            ]
            
            await updateIndex(for: .template, contentId: template.id.uuidString, content: content)
        }
    }
    
    private func indexCategories() async throws {
        let categories = [
            "Birthday": "Birthday celebrations and wishes",
            "Thank You": "Gratitude and appreciation messages",
            "Congratulations": "Achievement and success messages",
            "Get Well": "Health and recovery wishes",
            "Love & Romance": "Romantic and love messages",
            "Friendship": "Friendship and connection messages",
            "Holiday": "Holiday and seasonal greetings",
            "Sympathy": "Condolence and sympathy messages",
            "Motivation": "Inspirational and motivational content",
            "Business": "Professional and business communications"
        ]
        
        for (name, description) in categories {
            let content: [String: Any] = [
                "name": name,
                "description": description
            ]
            
            await updateIndex(for: .category, contentId: name, content: content)
        }
    }
    
    // MARK: - Index Entry Creation
    private func createIndexEntry(contentType: SearchResultType, contentId: String, content: [String: Any]) -> SearchIndexEntry {
        let searchableText = extractSearchableText(from: content, contentType: contentType)
        let keywords = generateKeywords(from: searchableText)
        
        return SearchIndexEntry(
            id: "\(contentType.rawValue)_\(contentId)",
            contentType: contentType,
            contentId: contentId,
            searchableText: searchableText,
            keywords: keywords,
            content: content,
            lastUpdated: Date()
        )
    }
    
    private func extractSearchableText(from content: [String: Any], contentType: SearchResultType) -> String {
        var text = ""
        
        switch contentType {
        case .message:
            if let subject = content["subject"] as? String {
                text += subject + " "
            }
            if let message = content["message"] as? String {
                text += message + " "
            }
            
        case .user:
            if let name = content["name"] as? String {
                text += name + " "
            }
            if let email = content["email"] as? String {
                text += email + " "
            }
            
        case .template:
            if let title = content["title"] as? String {
                text += title + " "
            }
            if let templateContent = content["content"] as? String {
                text += templateContent + " "
            }
            if let category = content["category"] as? String {
                text += category + " "
            }
            
        case .category:
            if let name = content["name"] as? String {
                text += name + " "
            }
            if let description = content["description"] as? String {
                text += description + " "
            }
        }
        
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func generateKeywords(from text: String) -> [String] {
        let words = text.lowercased()
            .components(separatedBy: .whitespacesAndPunctuation)
            .filter { !$0.isEmpty && $0.count > 2 }
        
        // Remove common stop words
        let stopWords = Set(["the", "and", "for", "are", "but", "not", "you", "all", "can", "had", "her", "was", "one", "our", "out", "day", "get", "has", "him", "his", "how", "its", "may", "new", "now", "old", "see", "two", "way", "who", "boy", "did", "man", "men", "put", "say", "she", "too", "use"])
        
        return Array(Set(words.filter { !stopWords.contains($0) }))
    }
    
    // MARK: - Scoring Algorithm
    private func calculateIndexScore(entry: SearchIndexEntry, queryWords: [String]) -> Double {
        var score = 0.0
        let text = entry.searchableText.lowercased()
        let keywords = entry.keywords.map { $0.lowercased() }
        
        for queryWord in queryWords {
            // Exact text match (highest score)
            if text.contains(queryWord) {
                score += 3.0
            }
            
            // Keyword match
            if keywords.contains(queryWord) {
                score += 2.0
            }
            
            // Partial keyword match
            for keyword in keywords {
                if keyword.contains(queryWord) || queryWord.contains(keyword) {
                    score += 1.0
                    break
                }
            }
            
            // Title/beginning match bonus
            if text.hasPrefix(queryWord) {
                score += 1.5
            }
        }
        
        // Boost score based on content type relevance
        switch entry.contentType {
        case .message:
            score *= 1.2 // Messages are most important
        case .user:
            score *= 1.1
        case .template:
            score *= 1.0
        case .category:
            score *= 0.9
        }
        
        return score
    }
    
    // MARK: - Helper Methods
    private func updateProgress(_ progress: Double) async {
        await MainActor.run {
            self.indexingProgress = progress
        }
    }
    
    private func updateLastIndexTime() async {
        await MainActor.run {
            self.lastIndexUpdate = Date()
        }
        
        // Store in UserDefaults
        UserDefaults.standard.set(Date(), forKey: "lastSearchIndexUpdate")
    }
    
    func getLastIndexUpdate() -> Date? {
        return UserDefaults.standard.object(forKey: "lastSearchIndexUpdate") as? Date
    }
    
    // MARK: - Index Maintenance
    func shouldRebuildIndex() -> Bool {
        guard let lastUpdate = getLastIndexUpdate() else {
            return true // Never indexed before
        }
        
        // Rebuild if index is older than 24 hours
        return Date().timeIntervalSince(lastUpdate) > 86400
    }
    
    func getIndexStats() async -> IndexStats {
        do {
            let snapshot = try await db.collection(indexCollection).getDocuments()
            
            let typeCount = Dictionary(grouping: snapshot.documents) { document in
                document.data()["contentType"] as? String ?? "unknown"
            }.mapValues { $0.count }
            
            return IndexStats(
                totalEntries: snapshot.documents.count,
                entriesByType: typeCount,
                lastUpdated: getLastIndexUpdate()
            )
            
        } catch {
            print("Error getting index stats: \(error)")
            return IndexStats(totalEntries: 0, entriesByType: [:], lastUpdated: nil)
        }
    }
}

// MARK: - Search Index Entry Model
struct SearchIndexEntry: Identifiable, Codable {
    let id: String
    let contentType: SearchResultType
    let contentId: String
    let searchableText: String
    let keywords: [String]
    let content: [String: String] // Simplified content storage
    let lastUpdated: Date
    
    init(id: String, contentType: SearchResultType, contentId: String, searchableText: String, keywords: [String], content: [String: Any], lastUpdated: Date) {
        self.id = id
        self.contentType = contentType
        self.contentId = contentId
        self.searchableText = searchableText
        self.keywords = keywords
        self.lastUpdated = lastUpdated
        
        // Convert content to string dictionary for Codable compliance
        var stringContent: [String: String] = [:]
        for (key, value) in content {
            if let stringValue = value as? String {
                stringContent[key] = stringValue
            } else if let dateValue = value as? Date {
                stringContent[key] = ISO8601DateFormatter().string(from: dateValue)
            } else {
                stringContent[key] = String(describing: value)
            }
        }
        self.content = stringContent
    }
}

// MARK: - Index Statistics
struct IndexStats {
    let totalEntries: Int
    let entriesByType: [String: Int]
    let lastUpdated: Date?
    
    var formattedLastUpdated: String {
        guard let lastUpdated = lastUpdated else {
            return "Never"
        }
        
        let formatter = RelativeDateTimeFormatter()
        return formatter.localizedString(for: lastUpdated, relativeTo: Date())
    }
}