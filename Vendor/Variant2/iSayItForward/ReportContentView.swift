import SwiftUI

struct ReportContentView: View {
    var body: some View {
        ZStack {
            Theme.vibrantGradient.ignoresSafeArea()

            VStack {
                Image(systemName: "exclamationmark.bubble.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.bottom, 20)

                Text("Report Content")
                    .font(.largeTitle.weight(.bold))
                    .foregroundColor(.white)

                Text("A placeholder screen for reporting content will be designed here.")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .padding()
        }
    }
}
