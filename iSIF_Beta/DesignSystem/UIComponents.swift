import SwiftUI

// MARK: - Social Icons (with asset fallback)
struct SocialRow: View {
    var onGoogle: () -> Void = {}
    var onMeta: () -> Void = {}
    var onApple: () -> Void = {}

    private func circle(_ image: Image) -> some View {
        image
            .resizable()
            .scaledToFit()
            .frame(width: 26, height: 26)
            .padding(10)
            .background(Circle().fill(Color.white.opacity(0.95)))
            .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
    }

    var body: some View {
        HStack(spacing: 22) {
            Button(action: onGoogle) {
                if UIImage(named: "googleLogo") != nil {
                    circle(Image("googleLogo"))
                } else {
                    circle(Image(systemName: "g.circle"))
                }
            }
            Button(action: onMeta) {
                if UIImage(named: "metaLogo") != nil {
                    circle(Image("metaLogo"))
                } else {
                    circle(Image(systemName: "m.circle"))
                }
            }
            Button(action: onApple) {
                circle(Image(systemName: "applelogo"))
            }
        }
    }
}

// MARK: - Info Card (Template Gallery / Schedule)
struct InfoCard: View {
    let title: String
    let subtitle: String
    let trailingSystemIcon: String

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(TextStyles.cardTitle()).foregroundColor(BrandColor.textDark)
                Text(subtitle).font(TextStyles.body()).foregroundColor(BrandColor.textDark.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            Image(systemName: trailingSystemIcon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(BrandColor.textDark)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
                .shadow(color: .black.opacity(0.12), radius: 2, y: 1)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.96))
                .shadow(color: .black.opacity(0.20), radius: 8, y: 6)
        )
    }
}
