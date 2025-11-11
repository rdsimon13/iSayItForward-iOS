import SwiftUI

struct MySIFsView: View {
    @EnvironmentObject var router: TabRouter
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray.full")
                .font(.system(size: 44))
                .foregroundColor(.gray)
            Text("My SIFs")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.gray)
            Text("You don’t have any SIFs yet.")
                .font(.subheadline)
                .foregroundColor(.gray.opacity(0.7))
            
            Button("Back to Home") {
                router.selectedTab = .home
            }
            .buttonStyle(.bordered)
            .padding(.top, 20)
        }
        .padding()
        .navigationTitle("My SIFs")
    }
}

#Preview {
    MySIFsView()
        .environmentObject(TabRouter())
}
