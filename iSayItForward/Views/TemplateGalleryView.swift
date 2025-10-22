import SwiftUI

struct TemplateGalleryView: View {
    let templates: [TemplateItem] = TemplateLibrary.templates
    @State private var selectedTab = "compose"
    @State private var navigateToSIF: TemplateItem? = nil
    @State private var scrollOffset: CGFloat = 0

    // Group templates by category
    var categorizedTemplates: [TemplateCategory: [TemplateItem]] {
        Dictionary(grouping: templates, by: { $0.category })
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // MARK: - Background Gradient
                GradientTheme.welcomeBackground
                    .ignoresSafeArea()

                // MARK: - Scrollable Template Sections
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        ForEach(TemplateCategory.allCases, id: \.self) { category in
                            if let items = categorizedTemplates[category], !items.isEmpty {
                                CategorySectionView(category: category, templates: items) { template in
                                    navigateToSIF = template
                                }
                            }
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 120)
                    .trackScrollOffset(in: "scroll", offset: $scrollOffset)
                }
                .coordinateSpace(name: "scroll")

                // MARK: - Bottom Navigation Bar
                BottomNavBar(selectedTab: $selectedTab, scrollOffsetBinding: $scrollOffset)
                    .onChange(of: selectedTab) { newTab in
                        navigateTo(tab: newTab)
                    }
            }
            .navigationTitle("Template Gallery")
            .navigationBarTitleDisplayMode(.inline)
            .background(
                Group {
                    if #available(iOS 17.0, *) {
                        NavigationLink(value: navigateToSIF) {
                            EmptyView()
                        }
                        .navigationDestination(for: TemplateItem.self) { template in
                            CreateSIFView(
                                preloadedSubject: template.name,
                                preloadedMessage: template.message,
                                preloadedImageName: template.imageName
                            )
                        }
                    } else {
                        NavigationLink(
                            destination: Group {
                                if let template = navigateToSIF {
                                    CreateSIFView(
                                        preloadedSubject: template.name,
                                        preloadedMessage: template.message,
                                        preloadedImageName: template.imageName
                                    )
                                }
                            },
                            isActive: Binding(
                                get: { navigateToSIF != nil },
                                set: { active in if !active { navigateToSIF = nil } }
                            )
                        ) {
                            EmptyView()
                        }
                        .hidden()
                    }
                }
            )
        }
    }

    // MARK: - Navigation
    private func navigateTo(tab: String) {
        switch tab {
        case "home": navigate(to: DashboardView())
        case "compose": navigate(to: CreateSIFView())
        case "profile": navigate(to: ProfileView())
        case "schedule": navigate(to: ScheduleSIFView())
        case "settings": navigate(to: GettingStartedView())
        default: break
        }
    }

    private func navigate<Destination: View>(to destination: Destination) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else { return }
        window.rootViewController = UIHostingController(rootView: destination)
        window.makeKeyAndVisible()
    }
}

// MARK: - Category Section View
struct CategorySectionView: View {
    let category: TemplateCategory
    let templates: [TemplateItem]
    let onSelect: (TemplateItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: category.icon)
                    .foregroundColor(.white)
                    .frame(width: 26, height: 26)
                    .background(category.color)
                    .clipShape(Circle())
                    .shadow(color: category.color.opacity(0.4), radius: 3, y: 2)

                Text(category.displayTitle)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(Color.brandDarkBlue)
            }
            .padding(.horizontal)

            VStack(spacing: 12) {
                ForEach(templates) { template in
                    TemplateCardView(template: template) {
                        onSelect(template)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Template Card View
private struct TemplateCardView: View {
    let template: TemplateItem
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(template.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.2), radius: 4, y: 2)

                VStack(alignment: .leading, spacing: 6) {
                    Text(template.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color.brandDarkBlue)
                        .multilineTextAlignment(.leading)

                    Text(template.message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(.white.opacity(0.95))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.1), radius: 8, y: 3)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NavigationStack {
        TemplateGalleryView()
    }
}
