import SwiftUI
import UIKit

enum AppAppearance {
    static func configure() {
        configureTabBarOpaque()
        configureNavBar()
    }

    private static func configureTabBarOpaque() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground   // light/blurred white look
        appearance.shadowColor = .clear                          // clean edge; set a color for a divider line if desired

        let tabBar = UITabBar.appearance()
        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }
        tabBar.isTranslucent = false
        tabBar.unselectedItemTintColor = UIColor.secondaryLabel
        tabBar.tintColor = UIColor.label
    }

    private static func configureNavBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]

        let navBar = UINavigationBar.appearance()
        navBar.standardAppearance = appearance
        navBar.compactAppearance = appearance
        navBar.scrollEdgeAppearance = appearance
        navBar.tintColor = UIColor.label
    }
}
