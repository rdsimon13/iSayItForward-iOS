import SwiftUI

public enum Tab: Int, CaseIterable { case home, compose, manage, schedule, settings }

public struct CustomTabBar: View {
    @Binding var selection: Tab
    public init(selection: Binding<Tab>) { self._selection = selection }
    public var body: some View {
        HStack(spacing: Theme.Spacing.xl) {
            ForEach(Tab.allCases, id: \\.self) { tab in
                Button { selection = tab } label: {
                    VStack(spacing: 4) {
                        Image(systemName: icon(for: tab)).font(.system(size: 18, weight: .semibold))
                        Circle().fill(selection == tab ? .white : .clear).frame(width: 4, height: 4)
                    }
                    .foregroundStyle(selection == tab ? .white : Theme.ColorToken.textSecondary)
                    .padding(10)
                    .background(selection == tab ? Theme.ColorToken.tabActive : .clear, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Theme.Spacing.xl)
        .padding(.vertical, Theme.Spacing.md)
        .background(.ultraThinMaterial, in: Capsule())
        .shadow(radius: 6)
        .padding(.bottom, Theme.Spacing.lg)
    }
    private func icon(for tab: Tab) -> String {
        switch tab {
        case .home: return "house.fill"
        case .compose: return "square.and.pencil"
        case .manage: return "tray.full.fill"
        case .schedule: return "calendar"
        case .settings: return "gearshape.fill"
        }
    }
}
