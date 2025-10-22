import Foundation
import Foundation

// MARK: - Template Item Model
struct TemplateItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let message: String
    let imageName: String
    let category: TemplateCategory
}
