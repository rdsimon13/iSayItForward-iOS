import SwiftUI

public struct RecipientPickerView: View {
    @Binding var selected: [SIFRecipient]
    @Environment(\.dismiss) var dismiss

    public init(selected: Binding<[SIFRecipient]>) {
        self._selected = selected
    }

    public var body: some View {
        VStack(spacing: 12) {
            Text("Recipient Picker").font(.headline)
            Button("Add Demo Recipient") {
                selected.append(SIFRecipient(name: "Demo User", email: "demo@isif.app"))
                dismiss()
            }
            Button("Close") { dismiss() }
        }
        .padding()
    }
}
