import SwiftUI

// MARK: - Report Overlay Modifier
struct ReportOverlayModifier: ViewModifier {
    @Binding var isReportPresented: Bool

    func body(content: Content) -> some View {
        content
            .overlay(
                ReportContentView(isPresented: $isReportPresented)
                    .opacity(isReportPresented ? 1 : 0)
                    .animation(.easeInOut(duration: 0.3), value: isReportPresented)
            )
    }
}

// MARK: - View Extension for Easy Access
extension View {
    /// Adds report functionality to any view
    /// - Parameter isPresented: Binding to control the report overlay visibility
    /// - Returns: View with report overlay capability
    func reportOverlay(isPresented: Binding<Bool>) -> some View {
        self.modifier(ReportOverlayModifier(isReportPresented: isPresented))
    }
}

// MARK: - Report Manager
/// A singleton manager to handle report functionality across the app
class ReportManager: ObservableObject {
    static let shared = ReportManager()

    @Published var isReportPresented = false
    @Published var reportContext: String = ""

    private init() {}

    /// Show the report overlay
    /// - Parameter context: Optional context about what is being reported
    func showReport(context: String = "") {
        reportContext = context
        withAnimation(.easeInOut(duration: 0.3)) {
            isReportPresented = true
        }
    }

    /// Hide the report overlay
    func hideReport() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isReportPresented = false
        }
    }
}

// MARK: - Global Report Overlay View
/// This view should be added at the root level of your app to enable system-wide reporting
struct GlobalReportOverlay: View {
    @StateObject private var reportManager = ReportManager.shared

    var body: some View {
        ReportContentView(isPresented: $reportManager.isReportPresented)
            .opacity(reportManager.isReportPresented ? 1 : 0)
            .animation(.easeInOut(duration: 0.3), value: reportManager.isReportPresented)
    }
}
