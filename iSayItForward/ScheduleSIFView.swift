import SwiftUI

struct ScheduleSIFView: View {
    @Binding var scheduledDate: Date

    var body: some View {
        Section(header: Text("Schedule")) {
            DatePicker("Send On", selection: $scheduledDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
        }
    }
}