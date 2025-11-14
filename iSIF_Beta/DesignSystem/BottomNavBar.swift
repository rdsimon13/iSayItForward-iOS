import SwiftUI

struct BottomNavBar: View {
    @Binding var selectedTab: AppTab
    @Binding var isVisible: Bool

    @EnvironmentObject var router: TabRouter
    @EnvironmentObject var authState: AuthState

    // Demo badge count; replace with your live count later
    var friendRequestCount: Int = 0

    var body: some View {
        VStack {
            if isVisible {
                HStack {
                    navButton(icon: AppTab.home.systemImage,       label: AppTab.home.title,       tab: .home)
                    navButton(icon: AppTab.compose.systemImage,    label: AppTab.compose.title,    tab: .compose)
                    navButton(icon: AppTab.gallery.systemImage,    label: AppTab.gallery.title,    tab: .gallery)
                    navButton(icon: AppTab.schedule.systemImage,   label: AppTab.schedule.title,   tab: .schedule)
                    navButton(icon: AppTab.sifConnect.systemImage, label: AppTab.sifConnect.title, tab: .sifConnect)
                    profileButton() 
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
            .foregroundColor(isActive ? Color(red: 0.65, green: 0.45, blue: 0.20)
                                      : .gray.opacity(0.8))
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private func profileButton() -> some View {
        let isActive = selectedTab == .profile
        return Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                selectedTab = .profile
                router.selectedTab = .profile
            }
        } label: {
            ZStack(alignment: .topTrailing) {
                // Avatar: Firebase photo if available, else app logo
                Group {
                    if let url = authState.photoURL {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let img): 
                                img.resizable().scaledToFill()
                            case .empty, .failure:
                                Image("isiFLogo")
                                    .resizable()
                                    .scaledToFill()
                            @unknown default:
                                Image("isiFLogo")
                                    .resizable()
                                    .scaledToFill()
                            }
                        }
                    } else {
                        Image("isiFLogo")
                            .resizable()
                            .scaledToFill()
                    }
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
                .scaleEffect(isActive ? 1.15 : 1.0)

                if friendRequestCount > 0 {
                    Text("\(friendRequestCount)")
                        .font(.system(size: 10, weight: .bold))
                        .padding(5)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 1))
                        .offset(x: 8, y: -6)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    BottomNavBar(selectedTab: .constant(.home), isVisible: .constant(true))
        .environmentObject(TabRouter())
        .environmentObject(AuthState())
        .frame(height: 120)
        .background(Color.gray.opacity(0.2))
}
