import SwiftUI
public struct AppBackground: ViewModifier {
    public init() {}
    public func body(content: Content) -> some View {
        ZStack { Theme.GradientToken.vibrant.ignoresSafeArea(); content }
    }
}
public extension View { func appBackground() -> some View { modifier(AppBackground()) } }
