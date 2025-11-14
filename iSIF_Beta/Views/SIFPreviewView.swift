import SwiftUI

struct SIFPreviewView: View {
    let sif: SIF

    var body: some View {
        VStack(spacing: 20) {
            // Template preview if available
            if let templateName = sif.templateName {
                Text("Template: \(templateName)")
                    .font(.headline)
            }
            
            // Text overlay preview
            if let textOverlay = sif.textOverlay {
                Text("Overlay: \(textOverlay)")
                    .font(.subheadline)
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(8)
            }
            
            // Signature preview
            if let signatureURL = sif.signatureURL {
                AsyncImage(url: signatureURL) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(height: 100)
                } placeholder: {
                    ProgressView()
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("To: \(sif.recipients.map { $0.name }.joined(separator: ", "))")
                if let deliveryDate = sif.deliveryDate {
                    Text("Scheduled For: \(deliveryDate.formatted(date: .long, time: .shortened))")
                }
                Text("Delivery Type: \(DeliveryType(rawValue: sif.deliveryType)?.displayTitle ?? sif.deliveryType)")
                Text("Delivery Channel: \(sif.deliveryChannel)")
                Text("Message:")
                    .font(.headline)
                Text("“\(sif.message)”")
                    .italic()
                
                // Attachments preview
                if let attachments = sif.attachments, !attachments.isEmpty {
                    Text("Attachments: \(attachments.count) file(s)")
                        .font(.subheadline)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)

            Spacer()

            Button("Confirm & Send") {
                // Logic to send would go here
            }
            .buttonStyle(PrimaryActionButtonStyle())
            
        }
        .padding()
        .navigationTitle("Review SIF")
    }
}
