import SwiftUI

struct BottomNavBar: View {
    // ✅ These bindings come from the parent view (SignatureView, TemplateGalleryView, etc.)
    @Binding var selectedTab: AppTab
    @Binding var isVisible: Bool

    @EnvironmentObject var router: TabRouter

    var body: some View {
        VStack {
            if isVisible {
                HStack {
                    navButton(icon: "house.fill", label: "Home", tab: .home)
                    navButton(icon: "square.and.pencil", label: "Compose", tab: .compose)
                    navButton(icon: "person.fill", label: "Profile", tab: .profile)
                    navButton(icon: "calendar", label: "Schedule", tab: .schedule)
                    navButton(icon: "photo.on.rectangle", label: "Gallery", tab: .gallery)
                    navButton(icon: "gearshape.fill", label: "Settings", tab: .settings)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                )
                .padding(.horizontal)
                .padding(.bottom, 5)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.25), value: isVisible)
            }
        }
    }

    // MARK: - Nav Button Helper
    private func navButton(icon: String, label: String, tab: AppTab) -> some View {
        let isActive = selectedTab == tab

        return Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                selectedTab = tab
                router.selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .scaleEffect(isActive ? 1.1 : 1.0)
                Text(label)
                    .font(.custom("Kodchasan-Medium", size: 10))
            }
            .foregroundColor(isActive ? Color(red: 0.65, green: 0.45, blue: 0.20) : .gray.opacity(0.8))
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    BottomNavBar(
        selectedTab: .constant(.home),
        isVisible: .constant(true)
    )
    .environmentObject(TabRouter())
    .frame(height: 120)
    .background(Color.gray.opacity(0.2))
}
