import SwiftUI

struct TestReportView: View {
    @State private var showReport = false

    var body: some View {
        VStack(spacing: 16) {
            Button("Show Report Modal") {
                showReport = true
            }
            .buttonStyle(PrimaryActionButtonStyle())

            Button("Use Report Manager") {
                ReportManager.shared.showReport(context: "Test content")
            }
            .buttonStyle(SecondaryActionButtonStyle())

            HStack {
                Text("Quick Report:")
                ReportButton {
                    print("Report tapped for Test item")
                }
                Spacer()
            }
            .padding(.horizontal)
        }
        .padding()
        .reportOverlay(isPresented: $showReport)
        .navigationTitle("Report Test")
    }
}
// MARK: - Preview
struct TestReportView_Previews: PreviewProvider {
    static var previews: some View {
        TestReportView()
    }
}
