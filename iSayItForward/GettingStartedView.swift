import SwiftUI

struct GettingStartedView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Getting Started")
                    .font(.custom("Kodchasan-Bold", size: 28))
                    .padding(.top, 40)

                Text("This is your quick guide to how iSayItForward works.")
                    .font(.custom("Kodchasan-Regular", size: 16))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Getting Started")
            .navigationBarTitleDisplayMode(.inline)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.9, green: 0.95, blue: 1.0),
                        Color(red: 0.7, green: 0.85, blue: 1.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
        }
    }
}

#Preview {
    GettingStartedView()
}
