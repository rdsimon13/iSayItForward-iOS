import SwiftUI

public struct ConfirmationView: View {
    public let sif: SIF
    public init(sif: SIF) { self.sif = sif }

    public var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill").font(.system(size: 54))
            Text("SIF Sent").font(.title2).bold()
            Text(sif.subject ?? "(No Subject)")
            Text("To: \(sif.recipients.map { $0.name }.joined(separator: ", "))")
        }
        .padding()
        .navigationTitle("Confirmation")
    }
}
