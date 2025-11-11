import SwiftUI

struct TemplateGalleryView: View {

    @Binding var selectedTemplate: TemplateModel?

    @EnvironmentObject var router: TabRouter
    @EnvironmentObject var authState: AuthState
    @Environment(\.dismiss) private var dismiss

    @State private var layoutMode: LayoutMode = .grid
    @State private var showSavedToast = false
    @State private var isLoading = false

    @State private var scrollOffset: CGFloat = 0
    @State private var lastScrollOffset: CGFloat = 0
    @State private var isNavVisible: Bool = true

    @State private var templates: [TemplateModel] = TemplateModel.sampleTemplates

    var body: some View {
        ZStack(alignment: .bottom) {
            BrandTheme.backgroundGradient
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    headerSection
                    layoutToggle

                    if isLoading {
                        ProgressView("Loading templates…")
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .foregroundColor(.gray)
                            .padding(.top, 40)
                    } else {
                        templateSection
                    }

                    Spacer(minLength: 140)
                }
                .padding(.horizontal, 20)
                .padding(.top, 40)
                .padding(.bottom, 120)
                .trackScrollOffset(in: "galleryScroll", offset: $scrollOffset)
            }
            .onChange(of: scrollOffset, initial: false) { _, newValue in
                handleScroll(offset: newValue)
            }

            BottomNavBar(selectedTab: $router.selectedTab, isVisible: $isNavVisible)
                .environmentObject(router)
                .padding(.bottom, 5)

            if showSavedToast {
                toastView
            }
        }
        .onAppear(perform: loadTemplates)
        .navigationBarHidden(true)
    }

    // MARK: Header
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Template Gallery")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundColor(BrandTheme.titleStroke)

            Text("Choose a message style to start your SIF.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(.black.opacity(0.75))
        }
        .multilineTextAlignment(.center)
    }

    // MARK: Layout Toggle
    private var layoutToggle: some View {
        HStack(spacing: 12) {
            toggleButton("Grid", icon: "square.grid.2x2", mode: .grid)
            toggleButton("List", icon: "list.bullet", mode: .list)
        }
        .font(.system(size: 15, weight: .semibold, design: .rounded))
        .foregroundColor(.black.opacity(0.8))
    }

    private func toggleButton(_ title: String, icon: String, mode: LayoutMode) -> some View {
        Button {
            withAnimation { layoutMode = mode }
        } label: {
            Label(title, systemImage: icon)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(
                    Capsule()
                        .fill(mode == layoutMode ? BrandTheme.pillBG.opacity(0.15) : Color.clear)
                )
        }
    }

    // MARK: Templates Section
    @ViewBuilder
    private var templateSection: some View {
        if layoutMode == .grid {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                ForEach(templates) { template in
                    TemplateThumbCard(template: template) {
                        handleSelect(template)
                    }
                }
            }
        } else {
            VStack(spacing: 20) {
                ForEach(templates) { template in
                    TemplateThumbCard(template: template) {
                        handleSelect(template)
                    }
                }
            }
        }
    }

    // MARK: Toast
    private var toastView: some View {
        Text("Template Selected ✓")
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(Capsule().fill(Color.green.opacity(0.9)))
            .shadow(radius: 4)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .padding(.bottom, 100)
    }

    // MARK: Actions
    private func handleSelect(_ template: TemplateModel) {
        selectedTemplate = template

        withAnimation { showSavedToast = true }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation { showSavedToast = false }
            dismiss()
        }
    }

    private func loadTemplates() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isLoading = false
        }
    }

    private func handleScroll(offset: CGFloat) {
        let delta = offset - lastScrollOffset
        if abs(delta) > 8 {
            withAnimation(.easeInOut(duration: 0.25)) {
                isNavVisible = delta > 0
            }
            lastScrollOffset = offset
        }
    }

    private enum LayoutMode { case grid, list }
}


// MARK: - Template Card View
private struct TemplateThumbCard: View {
    let template: TemplateModel
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {

                Image(systemName: template.icon ?? "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 80)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.black.opacity(0.8))
                    .padding()
                    .background(template.color)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .shadow(color: .black.opacity(0.15), radius: 4, y: 3)

                VStack(alignment: .leading, spacing: 4) {
                    Text(template.title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.black)

                    Text(template.subtitle)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.black.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.9))
            )
            .shadow(color: .black.opacity(0.1), radius: 6, y: 4)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    TemplateGalleryView(selectedTemplate: .constant(nil))
        .environmentObject(TabRouter())
        .environmentObject(AuthState())
}
