import SwiftUI

struct CapsuleField: View {
    let placeholder: String
    @Binding var text: String
    var secure: Bool = false

    // MARK: - Body
    var body: some View {
        Group {
            if secure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 18)
        .background(
            Capsule()
                .stroke(Color.black.opacity(0.25), lineWidth: 1)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.9))
                )
        )
        .font(TextStyles.body(15))
        .textInputAutocapitalization(.none)
        .autocorrectionDisabled(true)
    }

    // MARK: - Initializers
    /// ✅ Standard initializer using `secure:` label
    init(placeholder: String, text: Binding<String>, secure: Bool = false) {
        self.placeholder = placeholder
        self._text = text
        self.secure = secure
    }

    /// ✅ Convenience initializer for legacy calls using `isSecure:` label
    init(placeholder: String, text: Binding<String>, isSecure: Bool) {
        self.init(placeholder: placeholder, text: text, secure: isSecure)
    }
}
