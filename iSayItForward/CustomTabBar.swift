import SwiftUI

// Enum to define our tabs
enum Tab {
    case home, compose, profile, schedule, settings
}

struct CustomTabBar: View {
    @Binding var selectedTab: Tab

    var body: some View {
        HStack {
            TabBarButton(
                tab: .home,
                imageName: "homeIcon",
                text: "Home",
                selectedTab: $selectedTab
            )
            TabBarButton(
                tab: .compose,
                imageName: "composeIcon",
                text: "Compose",
                selectedTab: $selectedTab
            )
            TabBarButton(
                tab: .profile,
                imageName: "profileIcon",
                text: "Profile",
                selectedTab: $selectedTab
            )
            TabBarButton(
                tab: .schedule,
                imageName: "scheduleTabIcon",
                text: "Schedule",
                selectedTab: $selectedTab
            )
            TabBarButton(
                tab: .settings,
                imageName: "settingsIcon",
                text: "Settings",
                selectedTab: $selectedTab
            )
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.8))
        .cornerRadius(25)
        .shadow(radius: 10)
        .padding(.horizontal)
    }
}

// A reusable button for our custom tab bar
private struct TabBarButton: View {
    let tab: Tab
    let imageName: String
    let text: String
    @Binding var selectedTab: Tab
    
    private var isActive: Bool { tab == selectedTab }

    var body: some View {
        Button(action: { selectedTab = tab }) {
            VStack(spacing: 4) {
                Image(imageName) // Custom icon from Assets
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(height: 24)
                
                Text(text)
                    .font(.caption2)
            }
            .foregroundColor(isActive ? .white : .gray)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .background(isActive ? Theme.tabBrown : Color.clear)
            .cornerRadius(12)
            .animation(.easeInOut, value: isActive)
        }
    }
}
