import SwiftUI

struct GlobalFontModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.custom("isif-Regular", size: 17))
    }
}

extension View {
    func applyGlobalFont() -> some View {
        self.modifier(GlobalFontModifier())
    }
}
