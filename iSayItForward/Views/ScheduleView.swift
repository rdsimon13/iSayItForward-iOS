import SwiftUI

struct ScheduleView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("📅 Schedule a SIF")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Here you’ll be able to plan and schedule your SIFs for delivery on specific dates.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .navigationTitle("Schedule")
    }
}
