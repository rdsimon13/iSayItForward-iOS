import SwiftUI
import FirebaseAuth
import UIKit


/*
// MARK: - Drawing Path Model
struct DrawingPath: Identifiable {
    let id = UUID()
    var points: [CGPoint] = []
    var lineWidth: CGFloat = 2.0
}

// MARK: - Signature Canvas
struct SignatureCanvas: View {
    @Binding var paths: [DrawingPath]
    @State private var currentPath = DrawingPath()

    var body: some View {
        Canvas { context, _ in
            // Completed paths
            for path in paths {
                var cgPath = Path()
                if let first = path.points.first {
                    cgPath.move(to: first)
                    for point in path.points.dropFirst() {
                        cgPath.addLine(to: point)
                    }
                }
                context.stroke(cgPath, with: .color(.black), lineWidth: path.lineWidth)
            }

            // Current drawing path
            if let first = currentPath.points.first {
                var cgPath = Path()
                cgPath.move(to: first)
                for point in currentPath.points.dropFirst() {
                    cgPath.addLine(to: point)
                }
                context.stroke(cgPath, with: .color(.black), lineWidth: currentPath.lineWidth)
            }
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    currentPath.points.append(value.location)
                }
                .onEnded { _ in
                    if !currentPath.points.isEmpty {
                        paths.append(currentPath)
                        currentPath = DrawingPath()
                    }
                }
        )
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.15), radius: 5, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}
*/


// MARK: - Signature View
struct SignatureView: View {
    @Binding var isPresented: Bool
    let onSignatureComplete: (SignatureData) -> Void

    @EnvironmentObject var router: TabRouter
    @EnvironmentObject var authState: AuthState

    @State private var paths: [DrawingPath] = []
    @State private var showingClearAlert = false
    @State private var isNavVisible = true
    @State private var previewImage: UIImage? = nil
    @State private var showingSaveAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                // MARK: Background
                RadialGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(red: 0.0, green: 0.796, blue: 1.0), location: 0.0),
                        .init(color: .white, location: 1.0)
                    ]),
                    center: .top,
                    startRadius: 0,
                    endRadius: UIScreen.main.bounds.height
                )
                .ignoresSafeArea()

                VStack(spacing: 25) {
                    // MARK: Header
                    Text("Add Your Signature")
                        .font(.custom("AvenirNext-Bold", size: 24))
                        .foregroundColor(.black.opacity(0.85))
                        .padding(.top, 30)

 /*
                    // MARK: Signature Area
                    VStack(spacing: 10) {
                        SignatureCanvas(paths: $paths)
                            .frame(height: 220)

                        Text("Sign inside the box above")
                            .font(.custom("AvenirNext-Regular", size: 13))
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)

                    // MARK: Action Buttons
                    HStack(spacing: 16) {
                        Button("Clear") {
                            showingClearAlert = true
                        }
                        .font(.custom("AvenirNext-Regular", size: 16))
                        .foregroundColor(.black)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.9))
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.15), radius: 3, y: 2)

                        Button("Save Signature") {
                            saveSignature()
                        }
                        .font(.custom("AvenirNext-DemiBold", size: 16))
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(red: 0.15, green: 0.25, blue: 0.35))
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                    }
                    .padding(.horizontal)
*/
                    
                    // MARK: Preview Section
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

                    // MARK: Bottom Navigation
                    BottomNavBar(
                        selectedTab: $router.selectedTab,
                        isVisible: $isNavVisible
                    )
                    .environmentObject(router)
                    .environmentObject(authState)
                    .padding(.bottom, 5)
                }
                .alert("Clear Signature", isPresented: $showingClearAlert) {
                    Button("Clear", role: .destructive) { paths.removeAll() }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("Are you sure you want to clear your signature?")
                }
                .alert("Signature Saved", isPresented: $showingSaveAlert) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text("Your signature was captured successfully.")
                }
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: - Save Signature
    private func saveSignature() {
        guard let signatureImage = generateSignatureImage(),
              let imageData = signatureImage.pngData() else { return }

        previewImage = signatureImage

        let userUID = Auth.auth().currentUser?.uid ?? "anonymous"
        let signatureData = SignatureData(signatureImageData: imageData, userUID: userUID)
        onSignatureComplete(signatureData)
        showingSaveAlert = true
    }

    // MARK: - Generate Signature Image
    private func generateSignatureImage() -> UIImage? {
        // Auto-scale to the drawn size
        let size = CGSize(width: 400, height: 220)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            UIColor.black.setStroke()

            for path in paths {
                let bezierPath = UIBezierPath()
                bezierPath.lineWidth = path.lineWidth
                if let first = path.points.first {
                    bezierPath.move(to: first)
                    for point in path.points.dropFirst() {
                        bezierPath.addLine(to: point)
                    }
                    bezierPath.stroke()
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    SignatureView(isPresented: .constant(true)) { _ in }
        .environmentObject(TabRouter())
        .environmentObject(AuthState())
}
