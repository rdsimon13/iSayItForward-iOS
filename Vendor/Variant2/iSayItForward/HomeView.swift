import SwiftUI

struct HomeView: View {
    @State private var selectedTab: Tab = .home

    var body: some View {
        ZStack {
            Theme.vibrantGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // --- Header ---
                    Image("isifLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 50)
                        .shadow(radius: 3)
                        .padding(.top, 50) // Adjust for status bar

                    Text("iSayItForward")
                        .font(.custom("GillSans-Bold", size: 24))
                        .foregroundColor(Theme.textDark)
                    
                    Text("The Ultimate Way to Express Yourself")
                        .font(.custom("GillSans", size: 14))
                        .foregroundColor(Theme.textLightGray)
                        .padding(.bottom, 10)

                    // --- Welcome Card ---
                    WelcomeCard(userName: "Damon")

                    // --- Action Button Grid ---
                    HStack(spacing: 15) {
                        HomeActionButton(imageName: "gettingStartedIcon", text: "Getting Started") {}
                        HomeActionButton(imageName: "createSIFIcon", text: "CREATE A SIF") {}
                        HomeActionButton(imageName: "manageSIFIcon", text: "MANAGE MY SIF'S") {}
                    }
                    .padding(.top, 10)

                    // --- Promo Cards ---
                    SIFPromoCard(
                        title: "SIF Template Gallery",
                        description: "Explore a variety of ready made templates designed to help you express yourself with style and speed.",
                        imageName: "templateGalleryImage",
                        headerColor: Theme.darkTeal
                    )
                    
                    SIFPromoCard(
                        title: "Schedule a SIF",
                        description: "Never forget to send greetings on that special day ever again. Schedule your SIF for future delivery today!",
                        imageName: "scheduleSIFIcon",
                        headerColor: .purple
                    )
                    
                    // Add padding at the bottom to ensure content scrolls above the tab bar
                    Color.clear.frame(height: 100)
                }
                .padding(.horizontal)
            }
            
            // --- Custom Tab Bar Overlay ---
            VStack {
                Spacer()
                CustomTabBar(selectedTab: $selectedTab)
            }
        }
        .ignoresSafeArea(.all, edges: .bottom)
        .navigationBarHidden(true)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
