import SwiftUI

struct ReportUIDemo: View {
    @ObservedObject var reportManager = ReportManager.shared
    @State private var showReport = false

    var body: some View {
        ZStack {
            // FIXED: Use the new vibrant gradient
            Theme.vibrantGradient.ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Report UI Demo")
                    .font(.largeTitle.weight(.bold))
                    .foregroundColor(.white)

                Button("Launch Report Modal (Local State)") {
                    showReport = true
                }
                .buttonStyle(PrimaryButtonStyle())

                Button("Use Global Report Manager") {
                    reportManager.reportContext = "Demo content from ReportManager"
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
