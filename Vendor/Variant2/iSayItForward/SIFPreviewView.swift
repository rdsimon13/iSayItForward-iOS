import SwiftUI

struct SIFPreviewView: View {
    let sif: SIFItem

    var body: some View {
        VStack(spacing: 20) {
            // The image section has been removed since our new
            // SIFItem doesn't have an attachmentImageName property.

            VStack(alignment: .leading, spacing: 8) {
                Text("To: \(sif.recipients.joined(separator: ", "))")
                Text("Scheduled For: \(sif.scheduledDate.formatted(date: .long, time: .shortened))")
                Text("Message:")
                    .font(.headline)
                Text("“\(sif.message)”")
                    .italic()
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)

            Spacer()

            Button("Confirm & Send") {
                // Logic to send would go here
            }
            // Using one of our new button styles for consistency
            .buttonStyle(PrimaryButtonStyle())
appBackground()

appBackground()

appBackground()


            
        }
        .padding()
        .navigationTitle("Review SIF")
    }
}
