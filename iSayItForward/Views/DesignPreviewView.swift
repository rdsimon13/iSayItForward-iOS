import SwiftUI

struct DesignPreviewView: View {
    let swatches: [(String, Color)] = [
        ("blueTop", BrandColor.blueTop),
        ("blueMid", BrandColor.blueMid),
        ("blueBottom", BrandColor.blueBottom),
        ("navyStart", BrandColor.navyStart),
        ("navyEnd", BrandColor.navyEnd),
        ("gold", BrandColor.gold),
        ("goldDeep", BrandColor.goldDeep),
        ("textDark", BrandColor.textDark),
        ("surface", BrandColor.surface)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("iSayItForward • Palette Preview")
                    .font(TextStyles.appTitle(28)) // ✅ now defined
                    .padding(.bottom, 8)

                // Gradients
                VStack(alignment: .leading, spacing: 8) {
                    Text("Gradients")
                        .font(TextStyles.sectionTitle)

                    RoundedRectangle(cornerRadius: 16)
                        .fill(GradientTheme.primaryPill)
                        .frame(height: 52)
                        .overlay(Text("Primary Pill")
                            .foregroundColor(.white)
                            .font(.headline))

                    RoundedRectangle(cornerRadius: 16)
                        .fill(GradientTheme.goldPill)
                        .frame(height: 52)
                        .overlay(Text("Gold Pill")
                            .foregroundColor(BrandColor.textDark)
                            .font(.headline))

                    ZStack {
                        GradientTheme.welcomeBackground
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .frame(height: 120)
                            .overlay(Text("Welcome Background")
                                .font(.headline)
                                .foregroundColor(.white)
                                .shadow(radius: 3))
                    }
                }

                Divider()
                    .padding(.vertical, 6)
            }
            .padding()
        }
    }
}

#Preview {
    DesignPreviewView()
}
