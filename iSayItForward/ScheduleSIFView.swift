import SwiftUI

struct ScheduleSIFView: View {
    @Binding var scheduledDate: Date
    @State private var showingDatePicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Schedule Your SIF")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color.brandDarkBlue)
            
            VStack(spacing: 12) {
                Button(action: {
                    showingDatePicker.toggle()
                }) {
                    HStack {
                        Image(systemName: "calendar")
                            .font(.title2)
                            .foregroundColor(Color.brandDarkBlue)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Send On")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(scheduledDate.formatted(date: .abbreviated, time: .shortened))
                                .font(.headline)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                        
                        Image(systemName: showingDatePicker ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(.white.opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
                }
                .foregroundColor(Color.brandDarkBlue)
                
                if showingDatePicker {
                    DatePicker("Select Date & Time", selection: $scheduledDate, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.graphical)
                        .padding()
                        .background(.white.opacity(0.95))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.1), radius: 8, y: 3)
                        .transition(.opacity.combined(with: .scale))
                        .animation(.easeInOut(duration: 0.3), value: showingDatePicker)
                }
            }
        }
    }
}