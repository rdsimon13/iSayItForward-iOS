import SwiftUI

final class TabRouter: ObservableObject {
    @Published var selectedTab: AppTab = .home
    @Published var isNavVisible: Bool = true
    @Published var homeScrollToTop: Bool = false  // 👈 Added for scroll-to-top support
}
