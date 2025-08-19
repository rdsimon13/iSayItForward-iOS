import SwiftUI

struct TestReportView: View {
    @ObservedObject var reportManager = ReportManager.shared
    @State private var showReport = false

    var body: some View {
        ZStack {
            // FIXED: Use the new vibrant gradient
            Theme.vibrantGradient.ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Test Report View")
                    .font(.largeTitle.weight(.bold))
                    .foregroundColor(.white)

                Button("Show Report Modal") {
                    showReport = true
                }
                .buttonStyle(PrimaryButtonStyle())

                Button("Use Report Manager") {
                    reportManager.reportContext = "Test content"
                    reportManager.isReportPresented = true
                }
                .buttonStyle(PrimaryButtonStyle())

                Spacer()
            }
            .padding()
            .sheet(isPresented: $reportManager.isReportPresented) {
                Text("Report View Presented with context: \(reportManager.reportContext)")
            }
            .sheet(isPresented: $showReport) {
                Text("Report View Presented with local state")
            }
        }
    }
}
