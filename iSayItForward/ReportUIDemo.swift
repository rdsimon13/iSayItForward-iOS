import SwiftUI

// MARK: - Comprehensive Demo View
struct ReportUIDemo: View {
    @State private var showReport = false
    @State private var demoStep = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.mainAppGradient.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Text("Report UI Implementation")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(Color.brandDarkBlue)
                            
                            Text("System-wide reporting functionality with mockup-matching design")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        
                        // Features implemented
                        VStack(alignment: .leading, spacing: 16) {
                            Text("✅ Features Implemented")
                                .font(.headline)
                                .foregroundColor(Color.brandDarkBlue)
                            
                            FeatureRow(icon: "exclamationmark.triangle", 
                                     title: "Semi-transparent Dark Overlay",
                                     description: "40% black opacity overlay covers entire screen")
                            
                            FeatureRow(icon: "rectangle.roundedtop", 
                                     title: "Centered Modal Card",
                                     description: "White background, 16pt rounded corners, proper shadows")
                            
                            FeatureRow(icon: "list.bullet", 
                                     title: "Report Reasons List",
                                     description: "6 predefined reasons with chevron indicators")
                            
                            FeatureRow(icon: "text.cursor", 
                                     title: "Details Input Screen",
                                     description: "Text editor for additional context with submit button")
                            
                            FeatureRow(icon: "app.connected.to.app.below.fill", 
                                     title: "System-wide Access",
                                     description: "ReportManager singleton + ViewModifier for global access")
                            
                            FeatureRow(icon: "paintbrush", 
                                     title: "Consistent Styling",
                                     description: "Matches existing app design with brand colors")
                        }
                        .padding()
                        .background(.white.opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
                        
                        // Demo buttons
                        VStack(spacing: 16) {
                            Text("🎯 Demo Actions")
                                .font(.headline)
                                .foregroundColor(Color.brandDarkBlue)
                            
                            Button("Launch Report Modal") {
                                showReport = true
                            }
                            .buttonStyle(PrimaryActionButtonStyle())
                            
                            Button("Use Global Report Manager") {
                                ReportManager.shared.showReport(context: "Demo content from ReportManager")
                            }
                            .buttonStyle(SecondaryActionButtonStyle())
                            
                            HStack {
                                Text("Quick Report Button:")
                                    .foregroundColor(Color.brandDarkBlue)
                                ReportButton(context: "Quick action demo")
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                        .padding()
                        .background(.white.opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
                        
                        // Implementation details
                        VStack(alignment: .leading, spacing: 12) {
                            Text("🔧 Technical Implementation")
                                .font(.headline)
                                .foregroundColor(Color.brandDarkBlue)
                            
                            Text("• ReportContentView: Main modal with two-screen flow")
                            Text("• ReportOverlayModifier: ViewModifier for local overlay")
                            Text("• ReportManager: Singleton for global access")
                            Text("• GlobalReportOverlay: App-level overlay integration")
                            Text("• ReportButton: Reusable component for quick access")
                            Text("• Added to main app with ZStack overlay")
                            Text("• Fixed AppDelegate with UserNotifications setup")
                            Text("• Added notification permissions to Info.plist")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding()
                        .background(.white.opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .reportOverlay(isPresented: $showReport)
            .navigationTitle("Report UI Demo")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Feature Row Component
private struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Color.brandYellow)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.brandDarkBlue)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Preview
struct ReportUIDemo_Previews: PreviewProvider {
    static var previews: some View {
        ReportUIDemo()
    }
}