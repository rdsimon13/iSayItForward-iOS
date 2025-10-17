import SwiftUI

struct SettingsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("⚙️ Settings")
                .font(.title2)
                .fontWeight(.semibold)

            Text("This section will hold your user preferences, app appearance options, and other account-related settings.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .navigationTitle("Settings")
    }
}
