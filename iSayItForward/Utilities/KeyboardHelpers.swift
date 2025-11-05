import SwiftUI

// MARK: - Global Keyboard Helpers
extension View {
    /// Dismisses the keyboard when tapping outside a text field,
    /// while still allowing normal interaction with buttons and fields.
    func hideKeyboardOnTap() -> some View {
        self.gesture(
            TapGesture()
                .onEnded { _ in
                    UIApplication.shared.endEditing(true)
                    print("🩵 Keyboard dismissed")
                },
            including: .none // 👈 allows taps to reach TextFields and Buttons
        )
    }
}

extension UIApplication {
    /// Ends editing on the active key window to dismiss the keyboard globally.
    func endEditing(_ force: Bool) {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .endEditing(force)
    }
}
