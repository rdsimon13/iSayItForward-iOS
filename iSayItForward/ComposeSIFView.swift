import SwiftUI

struct ComposeSIFView: View {
    @Binding var recipient: String
    @Binding var message: String

    var body: some View {
        Section(header: Text("To")) {
            TextField("Recipient’s name", text: $recipient)
        }

        Section(header: Text("Message")) {
            if #available(iOS 16.0, *) {
                TextField("Your message", text: $message, axis: .vertical)
                    .lineLimit(5, reservesSpace: true)
            } else {
                TextField("Your message", text: $message)
                    .frame(minHeight: 100) // manually give it space
            }
        }
    }
}
