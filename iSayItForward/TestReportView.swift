import SwiftUI

// MARK: - Test Report Implementation View
struct TestReportView: View {
    @State private var showReport = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.mainAppGradient.ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Text("Report UI Test")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color.brandDarkBlue)
                    
                    Text("This view demonstrates the report functionality")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    // Test buttons
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
                            ReportButton(context: "Test item")
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .reportOverlay(isPresented: $showReport)
            .navigationTitle("Report Test")
        }
    }
}

// MARK: - Preview
struct TestReportView_Previews: PreviewProvider {
    static var previews: some View {
        TestReportView()
    }
}