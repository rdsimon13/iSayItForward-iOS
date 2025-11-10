import SwiftUI

/// Centralized handler for showing or submitting reports within the app.
final class ReportManager: ObservableObject {
    static let shared = ReportManager()

    @Published var isShowingReport = false
    @Published var reportContext: String = ""

    private init() {}

    /// Show the report UI with a given context
    func showReport(context: String) {
        reportContext = context
        isShowingReport = true
        print("📋 Showing report for context: \(context)")
    }

    /// Hide the report modal
    func dismissReport() {
        isShowingReport = false
    }
}
