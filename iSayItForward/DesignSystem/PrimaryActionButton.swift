import SwiftUI

struct PrimaryActionButton: View {
    let title: String
    var gradientColors: [Color]
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: gradientColors),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .cornerRadius(14)
                    .shadow(color: .black.opacity(0.25), radius: 4, y: 3)
                )
        }
    }
}
