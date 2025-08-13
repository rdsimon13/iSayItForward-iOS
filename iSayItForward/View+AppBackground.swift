import SwiftUI

extension View {
    /// Use the app gradient but only behind content (not under the Tab Bar) for Option A.
    func appGradientTopOnly() -> some View {
        self.background(Color.mainAppGradient.ignoresSafeArea(edges: .top))
    }

    /// Profile’s identity gradient (top only) to keep the white tab bar visible.
    func profileGradientTopOnly() -> some View {
        self.background(Color.profileGradient.ignoresSafeArea(edges: .top))
    }
}
