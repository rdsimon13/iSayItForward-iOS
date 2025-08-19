import SwiftUI

struct ScheduleSIFView: View {
    @State private var selectedDate = Date()

    var body: some View {
        ZStack {
            // FIXED: Use the new vibrant gradient background
            Theme.vibrantGradient.ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Schedule Your SIF")
                    .font(.largeTitle.weight(.bold))
                    .foregroundColor(.white)
                    .padding(.top)

                // The DatePicker is styled to be readable on the vibrant background
                DatePicker(
                    "Select a Date & Time",
                    selection: $selectedDate,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.graphical)
                .padding()
                .frostedGlass() // Use our frosted glass style
                .colorScheme(.dark) // This ensures the text inside the picker is white and legible

                Button("Confirm Schedule") {
                    // Action to save the selected date would go here
                }
                .buttonStyle(PrimaryButtonStyle()) // Use our updated white button style

                Spacer()
            }
            .padding()
            .navigationTitle("Schedule")
        }
    }
}

struct ScheduleSIFView_Previews: PreviewProvider {
    static var previews: some View {
        ScheduleSIFView()
    }
}
