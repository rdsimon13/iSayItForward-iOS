import SwiftUI

struct IOSCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            .shadow(radius: 4)
    }
}

extension View {
    func iosCard() -> some View {
        self.modifier(IOSCardModifier())
    }
}