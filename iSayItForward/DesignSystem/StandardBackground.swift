import SwiftUI

struct StandardBackground: View {
    var body: some View {
        AppGradient.standard
            .ignoresSafeArea()
    }
}

struct StandardBackground_Previews: PreviewProvider {
    static var previews: some View {
        StandardBackground()
    }
}
