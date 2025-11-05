import SwiftUI

struct MySIFsView: View {
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
        }
        .padding()
        .navigationTitle("My SIFs")
    }
}

#Preview {
    MySIFsView()
}
