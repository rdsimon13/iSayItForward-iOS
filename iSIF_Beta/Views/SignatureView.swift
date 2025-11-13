import SwiftUI
import FirebaseAuth
import UIKit

struct SignatureView: View {
    @Binding var isPresented: Bool
    let onSignatureComplete: (SignatureData) -> Void

    @EnvironmentObject var router: TabRouter
    @EnvironmentObject var authState: AuthState

    @State private var strokes: [SignatureStroke] = []
    @State private var showingClearAlert = false
    @State private var isNavVisible = true
    @State private var previewImage: UIImage? = nil
    @State private var showingSaveAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                RadialGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(red: 0.0, green: 0.796, blue: 1.0), location: 0.0),
                        .init(color: .white, location: 1.0)
                    ]),
                    center: .top, startRadius: 0, endRadius: UIScreen.main.bounds.height
                )
                .ignoresSafeArea()

                VStack(spacing: 25) {
                    Text("Add Your Signature")
                        .font(.custom("AvenirNext-Bold", size: 24))
                        .foregroundColor(.black.opacity(0.85))
                        .padding(.top, 30)

                    VStack(spacing: 10) {
                        SignatureCanvas(strokes: $strokes)
                            .frame(height: 220)

                        Text("Sign inside the box above")
                            .font(.custom("AvenirNext-Regular", size: 13))
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)

                    HStack(spacing: 16) {
                        Button("Clear") { showingClearAlert = true }
                            .font(.custom("AvenirNext-Regular", size: 16))
                            .foregroundColor(.black)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.white.opacity(0.9))
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.15), radius: 3, y: 2)

                        Button("Save Signature") { saveSignature() }
                            .font(.custom("AvenirNext-DemiBold", size: 16))
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(red: 0.15, green: 0.25, blue: 0.35))
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                    }
                    .padding(.horizontal)

                    if let previewImage {
                        VStack {
                            Text("Preview:")
                                .font(.custom("AvenirNext-Regular", size: 14))
                                .foregroundColor(.gray)
                            Image(uiImage: previewImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 160)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .padding(.horizontal)
                        }
                        .transition(.opacity)
                    }

                    Spacer()

                    BottomNavBar(selectedTab: $router.selectedTab, isVisible: $isNavVisible)
                        .environmentObject(router)
                        .environmentObject(authState)
                        .padding(.bottom, 5)
                }
                .alert("Clear Signature", isPresented: $showingClearAlert) {
                    Button("Clear", role: .destructive) { strokes.removeAll() }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("Are you sure you want to clear your signature?")
                }
                .alert("Signature Saved", isPresented: $showingSaveAlert) {
                    Button("OK") { isPresented = false }
                } message: {
                    Text("Your signature was captured successfully.")
                }
            }
            .navigationBarHidden(true)
        }
    }

    private func saveSignature() {
        guard let img = generateSignatureImage(),
              let data = img.pngData() else { return }
        previewImage = img

        let uid = Auth.auth().currentUser?.uid ?? "anonymous"
        let sig = SignatureData(signatureImageData: data, userUID: uid)
        onSignatureComplete(sig)
        showingSaveAlert = true
    }

    private func generateSignatureImage() -> UIImage? {
        let size = CGSize(width: 400, height: 220)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            UIColor.black.setStroke()

            for stroke in strokes {
                let path = UIBezierPath()
                path.lineWidth = stroke.lineWidth
                if let first = stroke.points.first {
                    path.move(to: first)
                    for p in stroke.points.dropFirst() { path.addLine(to: p) }
                    path.stroke()
                }
            }
        }
    }
}

#Preview {
    SignatureView(isPresented: .constant(true)) { _ in }
        .environmentObject(TabRouter())
        .environmentObject(AuthState())
}
