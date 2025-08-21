import SwiftUI
import ISIFDesignSystem

struct HomeSkinDemo: View {
    @State private var tab: Tab = .home
    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Text("iSayItForward").font(Theme.Typography.heading())
            Card {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    Text("Welcome back!").font(Theme.Typography.label())
                    Text("Let’s create your next SIF.").font(Theme.Typography.body())
                    PrimaryButton("Create a SIF") {}
                }
            }
            Spacer(minLength: 40)
            CustomTabBar(selection: $tab)
        }
        .padding(.horizontal, Theme.Spacing.xl)
        .appBackground()
    }
}
