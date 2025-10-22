import SwiftUI

struct BottomNavBar: View {
    @Binding var selectedTab: String
    var scrollOffset: CGFloat = 0     // 👈 Default plain value
    var scrollOffsetBinding: Binding<CGFloat>? = nil  // 👈 Optional binding for reactive scroll

    @State private var lastOffset: CGFloat = 0
    @State private var isVisible: Bool = true
    @State private var opacity: Double = 1.0
    @State private var scrollVelocity: CGFloat = 0

    @Environment(\.horizontalSizeClass) private var hSizeClass

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // MARK: - Background blur + gradient
                ZStack {
                    FrostedBlur(style: blurStyle(for: geo))
                    LinearGradient(
                        colors: [Color.white.opacity(0.35), Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius(for: geo)))
                .shadow(color: .black.opacity(0.15 * opacity), radius: 8, y: -2)

                // MARK: - Navigation Buttons
                HStack(spacing: spacing(for: geo)) {
                    navButton(icon: "house.fill", tab: "home", label: "Home", geo: geo)
                    navButton(icon: "square.and.pencil", tab: "compose", label: "Compose", geo: geo)
                    navButton(icon: "person.fill", tab: "profile", label: "Profile", geo: geo)
                    navButton(icon: "calendar", tab: "schedule", label: "Schedule", geo: geo)
                    navButton(icon: "gearshape.fill", tab: "settings", label: "Settings", geo: geo)
                }
                .padding(.horizontal, horizontalPadding(for: geo))
                .padding(.vertical, verticalPadding(for: geo))
            }
            .frame(height: navBarHeight)
            .padding(.horizontal, 20)
            .padding(.bottom, safeBottomInset)
            .offset(y: isVisible ? 0 : navBarHeight + safeBottomInset + 30)
            .opacity(opacity)
            .animation(.easeInOut(duration: 0.25), value: isVisible)
            .animation(.easeOut(duration: 0.2), value: opacity)
            // 👇 Track both — the binding if available, otherwise the plain value
            .onChange(of: scrollOffsetBinding?.wrappedValue ?? scrollOffset) { newValue in
                handleScrollChange(newValue)
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Scroll Behavior with Fade + Hide
    private func handleScrollChange(_ newValue: CGFloat) {
        let delta = newValue - lastOffset
        scrollVelocity = delta

        if delta < -12 {
            withAnimation(.easeInOut(duration: 0.25)) { isVisible = false }
        } else if delta > 12 {
            withAnimation(.easeInOut(duration: 0.25)) { isVisible = true }
        }

        let velocityMagnitude = abs(scrollVelocity)
        let targetOpacity = velocityMagnitude > 20 ? max(0.3, 1.0 - velocityMagnitude / 80) : 1.0

        withAnimation(.easeOut(duration: 0.2)) { opacity = targetOpacity }
        lastOffset = newValue
    }

    // MARK: - Nav Button Builder
    private func navButton(icon: String, tab: String, label: String, geo: GeometryProxy) -> some View {
        VStack(spacing: labelSpacing(for: geo)) {
            Image(systemName: icon)
                .font(.system(size: iconSize(for: geo), weight: .semibold))
                .foregroundColor(selectedTab == tab ? Color.brandDarkBlue : .gray.opacity(0.7))

            Text(label)
                .font(.custom("Kodchasan-SemiBold", size: fontSize(for: geo)))
                .foregroundColor(selectedTab == tab ? Color.brandDarkBlue : .gray.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tab
            }
        }
    }

    // MARK: - Adaptive Layout Logic
    private func iconSize(for geo: GeometryProxy) -> CGFloat {
        geo.size.width > 900 ? 26 : (geo.size.width > 600 ? 22 : 20)
    }
    private func fontSize(for geo: GeometryProxy) -> CGFloat {
        geo.size.width > 900 ? 14 : (geo.size.width > 600 ? 13 : 12)
    }
    private func spacing(for geo: GeometryProxy) -> CGFloat {
        geo.size.width > 900 ? 60 : (geo.size.width > 600 ? 50 : 40)
    }
    private func labelSpacing(for geo: GeometryProxy) -> CGFloat {
        geo.size.width > 900 ? 6 : 4
    }
    private func horizontalPadding(for geo: GeometryProxy) -> CGFloat {
        geo.size.width > 900 ? 30 : (geo.size.width > 600 ? 24 : 20)
    }
    private func verticalPadding(for geo: GeometryProxy) -> CGFloat {
        geo.size.width > 900 ? 16 : 12
    }
    private func cornerRadius(for geo: GeometryProxy) -> CGFloat {
        geo.size.width > 900 ? 40 : 30
    }
    private func blurStyle(for geo: GeometryProxy) -> UIBlurEffect.Style {
        geo.size.width > 900 ? .systemMaterial : .systemUltraThinMaterialLight
    }

    // MARK: - Constants
    private var navBarHeight: CGFloat { 90 }
    private var safeBottomInset: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.windows.first?.safeAreaInsets.bottom }
            .first ?? 10
    }
}

// MARK: - Previews
#Preview {
    Group {
        BottomNavBar(selectedTab: .constant("compose"))
            .previewDisplayName("iPhone 15 Pro")
            .previewLayout(.sizeThatFits)
            .frame(width: 400, height: 90)
            .background(Color.gray.opacity(0.2))

        BottomNavBar(selectedTab: .constant("compose"))
            .previewDisplayName("iPad Landscape")
            .previewLayout(.sizeThatFits)
            .frame(width: 1100, height: 90)
            .background(Color.gray.opacity(0.2))
    }
}

// MARK: - Local Frosted Blur Wrapper
private struct FrostedBlur: UIViewRepresentable {
    var style: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
