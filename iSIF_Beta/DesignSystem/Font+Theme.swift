import SwiftUI
import UIKit

struct FontTheme {
    static func setupGlobalFontAppearance() {
        print("🧩 Applying AvenirNextRounded font globally...")

        // Debug: List all font families that contain "Avenir"
        for family in UIFont.familyNames.sorted() {
            if family.lowercased().contains("avenir") {
                print("→ \(family): \(UIFont.fontNames(forFamilyName: family))")
            }
        }

        // UILabel global
        if let regular = UIFont(name: "AvenirNext-Regular", size: 17) {
            UILabel.appearance().font = regular
        } else {
            print("⚠️ AvenirNext-Regular not found, using system font fallback.")
        }

        // UIButton
        if let medium = UIFont(name: "AvenirNext-Medium", size: 17) {
            UIButton.appearance().titleLabel?.font = medium
        } else {
            print("⚠️ AvenirNext-Medium not found, using system font fallback.")
        }

        // UINavigationBar small title
        if let demiBold = UIFont(name: "AvenirNext-DemiBold", size: 20) {
            UINavigationBar.appearance().titleTextAttributes = [.font: demiBold]
        } else {
            print("⚠️ AvenirNext-DemiBold not found, skipping small title font.")
        }

        // UINavigationBar large title
        if let bold = UIFont(name: "AvenirNext-Bold", size: 34) {
            UINavigationBar.appearance().largeTitleTextAttributes = [.font: bold]
        } else {
            print("⚠️ AvenirNext-Bold not found, skipping large title font.")
        }

        print("✅ AvenirNextRounded font applied globally.")
    }
}
