import SwiftUI

struct SIFDetailView: View {
    let sif: SIFItem

    var body: some View {
        ZStack {
            // FIXED: Use the new vibrant gradient
            Theme.vibrantGradient.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // Detail Card for Key Information
                    VStack(alignment: .leading, spacing: 12) {
                        DetailRow(icon: "person.2.fill", title: "Recipients", value: sif.recipients.joined(separator: ", "))
                        Divider()
                        DetailRow(icon: "calendar", title: "Scheduled For", value: sif.scheduledDate.formatted(date: .long, time: .shortened))
                        Divider()
                        DetailRow(icon: "paperplane.fill", title: "Subject", value: sif.subject)
                    }
                    .foregroundColor(.white) // FIXED: Text color for readability
                    .frostedGlass() // FIXED: Use our new frosted glass style

                    // Card for the Message Body
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Message")
                            .font(.headline)
                        
                        Text(sif.message)
                            .font(.body)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(.white) // FIXED: Text color
                    .frostedGlass() // FIXED: Use our new frosted glass style

                    // Signature Display (if available)
                    if let signatureData = sif.signatureImageData,
                       let signatureTimestamp = sif.signatureTimestamp {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Digital Signature")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8)) // FIXED: Color
                            
                            if let uiImage = UIImage(data: signatureData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 60)
                                    .background(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            
                            Text("Signed on \(signatureTimestamp.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption2)
                        }
                        .foregroundColor(.white) // FIXED: Color
                        .frostedGlass() // FIXED: Use our new frosted glass style
                    }
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("SIF Details")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ReportButton {
                        print("Report tapped for SIF: \(sif.subject)")
                    }
                }
            }
        }
    }
}

// Helper view for a consistent row style in the detail card
private struct DetailRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .opacity(0.8) // Use opacity for secondary text on vibrant background
            }
            Text(value)
                .font(.body.weight(.semibold))
        }
    }
}

// NOTE: You will need to define a sample SIFItem for the preview to work.
// Make sure you have a SIFItem.swift file in your project.
/*
struct SIFDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SIFDetailView(sif: SIFItem(authorUid: "123", recipients: ["preview@example.com"], subject: "Preview Subject", message: "This is a longer preview message to see how the text wraps.", createdDate: Date(), scheduledDate: Date()))
        }
        .preferredColorScheme(.dark)
    }
}
*/
