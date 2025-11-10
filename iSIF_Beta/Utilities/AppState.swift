import SwiftUI

class AppState: ObservableObject {
    // Default tab for the app (Dashboard or Home)
    @Published var selectedTab: AppTab = .home

    // Optional: selected template (now uses TemplateModel)
    @Published var selectedTemplate: TemplateModel? = nil
}
