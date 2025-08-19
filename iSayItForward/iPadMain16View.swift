import SwiftUI

@available(iOS 16.0, *)
struct iPadMain16View: View {
    @Binding var selection: SidebarItem?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            List(SidebarItem.allCases, selection: $selection) { item in
                NavigationLink(value: item) {
                    item.label
                }
            }
            .navigationTitle("iSayItForward")
        } content: {
            switch selection {
            case .home:
                HomeView()
            case .createSIF:
                CreateSIFView()
            case .manageSIFs:
                MySIFsView()
            case .templates:
                TemplateGalleryView()
            case .profile:
                ProfileView()
            case .none:
                Text("Select a section from the sidebar.")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
        } detail: {
            Text("Detail View (e.g., open individual SIF here)")
                .font(.largeTitle)
                .foregroundColor(.gray)
        }
    }
}
