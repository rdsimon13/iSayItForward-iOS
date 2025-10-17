import SwiftUI

@available(iOS 16.0, *)
struct iPadMain16View: View {
    @Binding var selection: SidebarItem?   // ✅ Optional binding matches iPadMainView
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var selectedTab: Int = 0   // Tracks Home tab selection

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // ✅ Sidebar list (no unavailable init)
            List {
                ForEach(SidebarItem.allCases, id: \.self) { item in
                    NavigationLink(value: item) {
                        item.label
                    }
                }
            }
            .navigationTitle("iSayItForward")

        } content: {
            // ✅ Safely unwrap selection (since it's optional)
            if let selection = selection {
                switch selection {
                case .home:
                    HomeView(selectedTab: $selectedTab)
                case .createSIF:
                    CreateSIFView()
                case .manageSIFs:
                    MySIFsView()
                case .templates:
                    TemplateGalleryView()
                case .profile:
                    ProfileView()
                }
            } else {
                // Fallback view when nothing is selected
                Text("Select a section from the sidebar.")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }

        } detail: {
            Text("Detail View (e.g., open individual SIF here)")
                .font(.largeTitle)
        }
    }
}
