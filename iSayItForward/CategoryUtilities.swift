import Foundation
import SwiftUI

struct CategoryUtilities {
    
    // MARK: - Color Utilities
    static func hexToColor(_ hex: String) -> Color {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        return Color(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    static func colorToHex(_ color: Color) -> String {
        // This is a simplified version - in practice you'd use UIColor conversion
        return CategoryConstants.Defaults.categoryColor
    }
    
    // MARK: - Category Organization
    static func groupCategoriesByParent(_ categories: [Category]) -> [String: [Category]] {
        var grouped: [String: [Category]] = [:]
        
        for category in categories {
            let key = category.parentCategoryId ?? "root"
            if grouped[key] == nil {
                grouped[key] = []
            }
            grouped[key]?.append(category)
        }
        
        return grouped
    }
    
    static func buildCategoryHierarchy(_ categories: [Category]) -> [CategoryNode] {
        let grouped = groupCategoriesByParent(categories)
        let rootCategories = grouped["root"] ?? []
        
        return rootCategories.map { category in
            CategoryNode(
                category: category,
                children: buildChildNodes(for: category.id, from: grouped)
            )
        }
    }
    
    private static func buildChildNodes(for parentId: String?, from grouped: [String: [Category]]) -> [CategoryNode] {
        guard let parentId = parentId,
              let children = grouped[parentId] else {
            return []
        }
        
        return children.map { category in
            CategoryNode(
                category: category,
                children: buildChildNodes(for: category.id, from: grouped)
            )
        }
    }
    
    // MARK: - Search and Filtering
    static func filterCategories(_ categories: [Category], searchText: String) -> [Category] {
        guard !searchText.isEmpty else { return categories }
        
        let lowercased = searchText.lowercased()
        return categories.filter { category in
            category.name.lowercased().contains(lowercased) ||
            category.description.lowercased().contains(lowercased)
        }
    }
    
    static func sortCategories(_ categories: [Category], by sortOption: CategorySortOption) -> [Category] {
        switch sortOption {
        case .name:
            return categories.sorted { $0.name < $1.name }
        case .popularity:
            return categories.sorted { $0.messageCount > $1.messageCount }
        case .recent:
            return categories.sorted { ($0.lastUsedDate ?? Date.distantPast) > ($1.lastUsedDate ?? Date.distantPast) }
        case .custom:
            return categories.sorted { $0.sortOrder < $1.sortOrder }
        }
    }
    
    // MARK: - Tag Cloud Utilities
    static func calculateTagFontSize(_ tag: Tag, in tags: [Tag]) -> CGFloat {
        guard !tags.isEmpty else { return CGFloat(CategoryConstants.tagFontSizeRange.0) }
        
        let maxUsage = tags.map { $0.usageCount }.max() ?? 1
        let minUsage = tags.map { $0.usageCount }.min() ?? 1
        
        let range = maxUsage - minUsage
        let normalizedUsage = range > 0 ? Double(tag.usageCount - minUsage) / Double(range) : 0.5
        
        let minSize = CategoryConstants.tagFontSizeRange.0
        let maxSize = CategoryConstants.tagFontSizeRange.1
        let sizeRange = maxSize - minSize
        
        return CGFloat(minSize + (normalizedUsage * sizeRange))
    }
    
    static func arrangeTagsInCloud(_ tags: [Tag]) -> [[Tag]] {
        // Simple row-based arrangement
        let sortedTags = tags.sorted { $0.usageCount > $1.usageCount }
        var rows: [[Tag]] = []
        var currentRow: [Tag] = []
        var currentRowWidth: CGFloat = 0
        let maxRowWidth: CGFloat = 300
        
        for tag in sortedTags {
            let fontSize = calculateTagFontSize(tag, in: tags)
            let estimatedWidth = CGFloat(tag.name.count) * fontSize * 0.6 + 20 // rough estimation
            
            if currentRowWidth + estimatedWidth > maxRowWidth && !currentRow.isEmpty {
                rows.append(currentRow)
                currentRow = [tag]
                currentRowWidth = estimatedWidth
            } else {
                currentRow.append(tag)
                currentRowWidth += estimatedWidth
            }
        }
        
        if !currentRow.isEmpty {
            rows.append(currentRow)
        }
        
        return rows
    }
    
    // MARK: - Analytics Utilities
    static func calculateTrendingScore(for tag: Tag) -> Double {
        let daysSinceLastUsed = Calendar.current.dateComponents([.day], 
                                                               from: tag.lastUsedDate ?? Date.distantPast, 
                                                               to: Date()).day ?? Int.max
        
        let recencyFactor = max(0, 1.0 - Double(daysSinceLastUsed) / 7.0) // Decay over 7 days
        let popularityFactor = min(1.0, Double(tag.usageCount) / 1000.0) // Normalize to 1000 uses
        
        return (recencyFactor * 0.6) + (popularityFactor * 0.4)
    }
    
    static func formatUsageCount(_ count: Int) -> String {
        if count < 1000 {
            return "\(count)"
        } else if count < 1_000_000 {
            return String(format: "%.1fK", Double(count) / 1000.0)
        } else {
            return String(format: "%.1fM", Double(count) / 1_000_000.0)
        }
    }
    
    // MARK: - Date Utilities
    static func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    static func isDateInPeriod(_ date: Date, period: StatsPeriod) -> Bool {
        return date >= period.startDate && date <= period.endDate
    }
}

// MARK: - Supporting Types
struct CategoryNode {
    let category: Category
    let children: [CategoryNode]
    
    var hasChildren: Bool {
        !children.isEmpty
    }
    
    var allDescendants: [Category] {
        var result = children.map { $0.category }
        for child in children {
            result.append(contentsOf: child.allDescendants)
        }
        return result
    }
}

enum CategorySortOption: String, CaseIterable {
    case name = "name"
    case popularity = "popularity"
    case recent = "recent"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .name: return "Name"
        case .popularity: return "Popularity"
        case .recent: return "Recently Used"
        case .custom: return "Custom Order"
        }
    }
    
    var iconName: String {
        switch self {
        case .name: return "textformat.abc"
        case .popularity: return "chart.bar.fill"
        case .recent: return "clock.fill"
        case .custom: return "slider.horizontal.3"
        }
    }
}