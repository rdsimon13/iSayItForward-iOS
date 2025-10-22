import SwiftUI

struct ScheduleSIFView: View {
    @State private var scheduledDate = Date()
    @State private var message: String = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Schedule a SIF")
                .font(.custom("Kodchasan-Bold", size: 28))
                .padding(.top, 40)

            Text("Never forget to send greetings again! Schedule your SIF to be delivered automatically on the date you choose.")
                .font(.custom("Kodchasan-Regular", size: 16))
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            DatePicker("Select a date and time", selection: $scheduledDate, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.graphical)
                .padding()

            TextField("Add an optional message", text: $message)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal, 40)

            Button {
                // placeholder for scheduling logic
                print("Scheduled SIF for \(scheduledDate) with message: \(message)")
            } label: {
                Text("Confirm Schedule")
                    .font(.custom("Kodchasan-SemiBold", size: 18))
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(red: 0.15, green: 0.25, blue: 0.35))
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
            }
            .padding(.horizontal, 40)

            Spacer()
        }
        .navigationTitle("Schedule a SIF")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ScheduleSIFView()
}
