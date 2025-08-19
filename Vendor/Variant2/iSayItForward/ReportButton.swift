import SwiftUI

struct ReportButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "exclamationmark.bubble")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
    }
}
