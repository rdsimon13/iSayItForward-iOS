import SwiftUI

struct SIFConfirmationView: View {
    let message: String
    let recipient: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(.green)
            Text("SIF Sent!")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("Your message to \(recipient) is on its way.")
                .font(.title2)
            Text("“\(message)”")
                .italic()
                .padding(.top, 20)
            Spacer()
        }
        .padding()
    }
}