import SwiftUI

struct SendSIFView: View {
    // This is for the action to perform when the button is tapped.
    let onSend: () -> Void

    var body: some View {
        Button("Send SIF") {
            onSend()
        }
        // Replacing the old, deleted style with our new, working button style.
        .buttonStyle(PrimaryButtonStyle())
appBackground()

appBackground()

appBackground()


    }
}
