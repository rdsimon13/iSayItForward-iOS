import Foundation

struct TagValidation {
    
    enum ValidationError: LocalizedError {
        case tooShort
        case tooLong
        case invalidCharacters
        case reserved
        case duplicate
        case empty
        case tooManyTags
        
        var errorDescription: String? {
            switch self {
            case .tooShort:
                return CategoryConstants.ErrorMessages.tagTooShort
            case .tooLong:
                return CategoryConstants.ErrorMessages.tagTooLong
            case .invalidCharacters:
                return CategoryConstants.ErrorMessages.invalidTagName
            case .reserved:
                return CategoryConstants.ErrorMessages.reservedTagName
            case .duplicate:
                return CategoryConstants.ErrorMessages.duplicateTag
            case .empty:
                return "Tag cannot be empty"
            case .tooManyTags:
                return CategoryConstants.ErrorMessages.tooManyTags
            }
        }
    }
    
    // MARK: - Single Tag Validation
    static func validateTag(_ tagName: String) -> Result<String, ValidationError> {
        let trimmed = tagName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if empty
        guard !trimmed.isEmpty else {
            return .failure(.empty)
        }
        
        // Remove # prefix if present
        let cleaned = trimmed.hasPrefix("#") ? String(trimmed.dropFirst()) : trimmed
        
        // Check length
        guard cleaned.count >= CategoryConstants.minTagLength else {
            return .failure(.tooShort)
        }
        
        guard cleaned.count <= CategoryConstants.maxTagLength else {
            return .failure(.tooLong)
        }
        
        // Check characters (alphanumeric only)
        guard cleaned.allSatisfy({ $0.isLetter || $0.isNumber }) else {
            return .failure(.invalidCharacters)
        }
        
        // Check reserved names
        guard !CategoryConstants.isReservedTag(cleaned) else {
            return .failure(.reserved)
        }
        
        return .success(cleaned.lowercased())
    }
    
    // MARK: - Multiple Tags Validation
    static func validateTags(_ tags: [String], existingTags: [String] = []) -> Result<[String], ValidationError> {
        // Check count limit
        guard tags.count <= CategoryConstants.maxTagsPerMessage else {
            return .failure(.tooManyTags)
        }
        
        var validatedTags: [String] = []
        var seenTags = Set<String>()
        
        for tag in tags {
            switch validateTag(tag) {
            case .success(let validTag):
                // Check for duplicates within the input
                guard !seenTags.contains(validTag) else {
                    return .failure(.duplicate)
                }
                
                // Check for duplicates with existing tags
                guard !existingTags.contains(validTag) else {
                    return .failure(.duplicate)
                }
                
                seenTags.insert(validTag)
                validatedTags.append(validTag)
                
            case .failure(let error):
                return .failure(error)
            }
        }
        
        return .success(validatedTags)
    }
    
    // MARK: - Tag Input Parsing
    static func parseTagInput(_ input: String) -> [String] {
        return input
            .components(separatedBy: CharacterSet(charactersIn: ",;\n "))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    // MARK: - Tag Formatting
    static func formatTag(_ tag: String) -> String {
        let cleaned = tag.hasPrefix("#") ? String(tag.dropFirst()) : tag
        return cleaned.lowercased()
    }
    
    static func displayTag(_ tag: String) -> String {
        "#\(tag)"
    }
    
    // MARK: - Suggestion Filtering
    static func filterSuggestions(_ suggestions: [TagSuggestion], existingTags: [String]) -> [TagSuggestion] {
        let existingSet = Set(existingTags.map { $0.lowercased() })
        return suggestions.filter { !existingSet.contains($0.tagName.lowercased()) }
    }
    
    // MARK: - Tag Similarity
    static func calculateSimilarity(_ tag1: String, _ tag2: String) -> Double {
        let normalized1 = tag1.lowercased()
        let normalized2 = tag2.lowercased()
        
        // Exact match
        if normalized1 == normalized2 {
            return 1.0
        }
        
        // Levenshtein distance based similarity
        let distance = levenshteinDistance(normalized1, normalized2)
        let maxLength = max(normalized1.count, normalized2.count)
        
        guard maxLength > 0 else { return 0.0 }
        
        return 1.0 - (Double(distance) / Double(maxLength))
    }
    
    private static func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let arr1 = Array(s1)
        let arr2 = Array(s2)
        let m = arr1.count
        let n = arr2.count
        
        var dp = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)
        
        for i in 0...m {
            dp[i][0] = i
        }
        
        for j in 0...n {
            dp[0][j] = j
        }
        
        for i in 1...m {
            for j in 1...n {
                if arr1[i-1] == arr2[j-1] {
                    dp[i][j] = dp[i-1][j-1]
                } else {
                    dp[i][j] = min(dp[i-1][j], dp[i][j-1], dp[i-1][j-1]) + 1
                }
            }
        }
        
        return dp[m][n]
    }
}