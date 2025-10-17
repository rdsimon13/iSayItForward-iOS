import SwiftUI

/// Centralized gradient styles used across the iSayItForward app.
/// Provides consistent background and accent gradient options.
enum AppGradient {
    
    /// The main app gradient (used for backgrounds like splash, login, etc.)
    static let standard = LinearGradient(
        gradient: Gradient(colors: [
            BrandColor.blueTop,
            BrandColor.blueMid,
            BrandColor.blueBottom
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// A gold-accented gradient (for highlighting or call-to-action areas)
    static let goldAccent = LinearGradient(
        gradient: Gradient(colors: [
            BrandColor.gold,
            BrandColor.goldDeep
        ]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    /// A dark navy background gradient (used in modals or overlays)
    static let darkBackground = LinearGradient(
        gradient: Gradient(colors: [
            BrandColor.navyStart,
            BrandColor.navyEnd
        ]),
        startPoint: .top,
        endPoint: .bottom
    )
}
