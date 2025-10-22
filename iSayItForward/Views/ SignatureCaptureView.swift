import SwiftUI

struct SignatureCaptureView: View {
    @Environment(\.dismiss) var dismiss
    @State private var signature: UIImage?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Add Your Signature")
                    .font(.system(size: 22, weight: .bold, design: .rounded))

                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.95))
                        .frame(height: 250)
                        .shadow(radius: 3)

                    Text("Signature Canvas Placeholder")
                        .foregroundColor(.gray)
                        .italic()
                }

                Spacer()

                Button("Save Signature") {
                    dismiss()
                }
                .font(.system(size: 18, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(14)
                .padding(.horizontal)
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
