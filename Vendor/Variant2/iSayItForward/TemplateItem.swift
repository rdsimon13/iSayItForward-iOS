import Foundation

enum TemplateCategory: String, CaseIterable {
    case encouragement = "Encouragement"
    case holiday = "Holiday"
    case announcement = "Announcement"
    case sympathy = "Sympathy"
    case school = "School"
    case spiritual = "Spiritual"
    case patriotic = "Patriotic"
    case seasonal = "Seasonal"
    case blank = "Blank"
}

struct TemplateItem: Identifiable {
    let id = UUID()
    let name: String
    let message: String
    let imageName: String
    let category: TemplateCategory
}
