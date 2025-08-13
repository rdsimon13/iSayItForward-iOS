import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            // Replaced the old gradient with our new app-wide theme gradient
            self.appGradientTopOnly()

            Image("isifLogo") // This must match the name in your Assets catalog
                .resizable()
                .scaledToFit()
                .frame(width: 110, height: 110)
                .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
        }
    }
}

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView()
    }
}
