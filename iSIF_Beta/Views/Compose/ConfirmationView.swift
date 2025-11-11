import SwiftUI

struct ConfirmationView: View {
    let sif: SIF
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            BrandTheme.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                
                Text("SIF Sent Successfully!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("To: \(sif.recipients.map { $0.name }.joined(separator: ", "))")
                    Text("Subject: \(sif.subject ?? "No Subject")")
                    Text("Delivery: \(sif.deliveryType.rawValue)")
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.9))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 20)
                
                Spacer()
            }
            .padding(.top, 60)
        }
    }
}
