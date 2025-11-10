import SwiftUI

struct SignaturePreviewView: View {
    @State private var showSignatureSheet = false
    @State private var localSignature: SignatureData
    let onEditComplete: (SignatureData) -> Void

    init(signatureData: SignatureData, onEditComplete: @escaping (SignatureData) -> Void) {
        _localSignature = State(initialValue: signatureData)
        self.onEditComplete = onEditComplete
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Your Signature")
                .font(.custom("Kodchasan-Bold", size: 20))
                .foregroundColor(.black.opacity(0.85))

            ZStack {
                if let uiImage = UIImage(data: localSignature.signatureImageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 300, maxHeight: 150)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .black.opacity(0.15), radius: 5, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                } else {
                    Text("No valid signature available")
                        .foregroundColor(.gray)
                        .font(.custom("AvenirNext-Regular", size: 14))
                        .frame(maxWidth: 300, maxHeight: 150)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                }

                // Overlay edit prompt
                VStack {
                    Spacer()
                    Text("✏️ Tap to edit")
                        .font(.custom("AvenirNext-Regular", size: 13))
                        .foregroundColor(.black.opacity(0.6))
                        .padding(.bottom, 6)
                }
            }
            .onTapGesture {
                showSignatureSheet = true
            }

            Text("Signed on \(localSignature.timestamp.formatted(date: .abbreviated, time: .shortened))")
                .font(.custom("AvenirNext-Regular", size: 13))
                .foregroundColor(.gray.opacity(0.8))
        }
        .padding()
        .sheet(isPresented: $showSignatureSheet) {
            SignatureView(isPresented: $showSignatureSheet) { newSig in
                localSignature = newSig
                onEditComplete(newSig)
            }
        }
    }
}

#Preview {
    // Mock preview for testing
    let dummyImage = UIImage(systemName: "scribble.variable")!
    let dummyData = dummyImage.pngData() ?? Data()
    let sampleSignature = SignatureData(signatureImageData: dummyData, userUID: "demoUser")

    SignaturePreviewView(signatureData: sampleSignature) { _ in }
}
