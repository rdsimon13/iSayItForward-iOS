import SwiftUI

@available(iOS 16.0, *)
struct iPadMain16View: View {
    @Binding var selection: SidebarItem?   // Optional binding matches iPadMainView
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var selectedTab: Int = 0   // Tracks Home tab selection

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // MARK: - Sidebar List
            List(selection: $selection) {
                ForEach(SidebarItem.allCases, id: \.self) { item in
                    NavigationLink(value: item) {
                        item.label
                    }
                }
            }
            .navigationTitle("iSayItForward")
            .listStyle(.sidebar)

        } content: {
            // MARK: - Main Content
            if let selection = selection {
                switch selection {
                case .home:
                    HomeView(selectedTab: $selectedTab)
                case .createSIF:
                    CreateSIFView()
                case .manageSIFs:
                    MySIFsView()
                case .gallery:
                    TemplateGalleryView(selectedTemplate: .constant(nil))
                case .profile:
                    ProfileView()
                }
            } else {
                // Default / fallback
                VStack(spacing: 16) {
                    Image(systemName: "hand.raised.heart.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.accentColor)
                    Text("Select a section from the sidebar.")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }

        } detail: {
            Text("Detail View (e.g., open individual SIF here)")
                .font(.largeTitle)
        }
    }
}
