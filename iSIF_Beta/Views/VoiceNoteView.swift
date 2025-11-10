
import SwiftUI

struct VoiceNoteView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "mic.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(height: 100)
                .foregroundColor(.teal.opacity(0.7))
            Text("Voice recording feature coming soon.")
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(14)
        .shadow(radius: 4)
    }
}
