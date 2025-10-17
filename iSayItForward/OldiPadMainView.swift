import SwiftUI

struct iPadMainView: View {
    @State private var selection: SidebarItem? = .home

    var body: some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            if #available(iOS 16.0, *) {
                iPadMain16View(selection: $selection)
            } else {
                Text("This iPad version of the app requires iOS 16.0 or newer.")
                    .font(.headline)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        } else {
            EmptyView() // iPhone will never route here
        }
    }
}
