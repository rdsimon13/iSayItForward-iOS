import SwiftUI

extension View {
    // This modifier now applies our new theme's gradient background
    func appBackground() -> some View {
        self.background(Theme.vibrantGradient.ignoresSafeArea())
    }
}
