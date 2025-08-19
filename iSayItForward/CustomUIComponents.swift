import SwiftUI

// MARK: - Welcome Card
struct WelcomeCard: View {
    let userName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            (Text("Welcome to iSIF, ") + Text(userName).bold() + Text("."))
            Text("Choose an option below to get started.")
        }
        .font(.system(size: 16))
        .foregroundColor(Theme.textDark)
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.7))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
        )
    }
}

// MARK: - Home Action Button
struct HomeActionButton: View {
    let imageName: String
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(imageName) // Custom image from Assets
                    .resizable()
                    .scaledToFit()
                    .frame(height: 40)
                
                Text(text)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Theme.textDark)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 100)
            .background(Color.white.opacity(0.7))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
            )
        }
    }
}

// MARK: - SIF Promo Card
struct SIFPromoCard: View {
    let title: String
    let description: String
    let imageName: String
    let headerColor: Color

    var body: some View {
        VStack(spacing: 0) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(headerColor)

            HStack {
                Text(description)
                    .font(.caption)
                    .foregroundColor(Theme.textDark)
                    .padding([.leading, .vertical])

                Spacer()

                Image(imageName) // Custom image from Assets
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 60)
                    .padding(.trailing)
            }
            .background(.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.2), radius: 5, y: 3)
    }
}
