import SwiftUI
import FirebaseAuth

// MARK: - Signature Data Model
struct SignatureData: Identifiable, Codable {
    let id = UUID()
    let signatureImageData: Data
    let timestamp: Date
    let userUID: String
    
    init(signatureImageData: Data, userUID: String) {
        self.signatureImageData = signatureImageData
        self.timestamp = Date()
        self.userUID = userUID
    }
}

// MARK: - Canvas Drawing Data
struct DrawingPath {
    var points: [CGPoint] = []
    var lineWidth: CGFloat = 2.0
}

// MARK: - Signature Canvas
struct SignatureCanvas: View {
    @Binding var paths: [DrawingPath]
    @State private var currentPath = DrawingPath()
    
    var body: some View {
        Canvas { context, size in
            // Draw all completed paths
            for path in paths {
                var cgPath = Path()
                if !path.points.isEmpty {
                    cgPath.move(to: path.points[0])
                    for point in path.points.dropFirst() {
                        cgPath.addLine(to: point)
                    }
                }
                context.stroke(cgPath, with: .color(.primary), lineWidth: path.lineWidth)
            }
            
            // Draw current path being drawn
            if !currentPath.points.isEmpty {
                var cgPath = Path()
                cgPath.move(to: currentPath.points[0])
                for point in currentPath.points.dropFirst() {
                    cgPath.addLine(to: point)
                }
                context.stroke(cgPath, with: .color(.primary), lineWidth: currentPath.lineWidth)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let point = value.location
                    currentPath.points.append(point)
                }
                .onEnded { _ in
                    if !currentPath.points.isEmpty {
                        paths.append(currentPath)
                        currentPath = DrawingPath()
                    }
                }
        )
    }
}

// MARK: - Main Signature View
struct SignatureView: View {
    @Binding var isPresented: Bool
    @State private var paths: [DrawingPath] = []
    @State private var showingClearAlert = false
    
    let onSignatureComplete: (SignatureData) -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.mainAppGradient.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("Please sign below")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.brandDarkBlue)
                        .padding(.top)
                    
                    // Signature canvas area
                    VStack {
                        SignatureCanvas(paths: $paths)
                            .frame(height: 200)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        
                        Text("Sign your name above")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.top, 4)
                    }
                    .padding(.horizontal)
                    
                    // Action buttons
                    HStack(spacing: 16) {
                        Button("Clear") {
                            if !paths.isEmpty {
                                showingClearAlert = true
                            }
                        }
                        .buttonStyle(SecondaryActionButtonStyle())
                        .disabled(paths.isEmpty)
                        
                        Button("Save Signature") {
                            saveSignature()
                        }
                        .buttonStyle(PrimaryActionButtonStyle())
                        .disabled(paths.isEmpty)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .navigationTitle("Add Signature")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
            .alert("Clear Signature", isPresented: $showingClearAlert) {
                Button("Clear", role: .destructive) {
                    paths.removeAll()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to clear your signature?")
            }
        }
    }
    
    private func saveSignature() {
        guard let signatureImage = generateSignatureImage() else { return }
        guard let imageData = signatureImage.pngData() else { return }
        
        // Get current user UID from Firebase Auth
        let userUID = Auth.auth().currentUser?.uid ?? "anonymous"
        
        let signatureData = SignatureData(signatureImageData: imageData, userUID: userUID)
        onSignatureComplete(signatureData)
        isPresented = false
    }
    
    private func generateSignatureImage() -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 300, height: 150))
        return renderer.image { context in
            // White background
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 300, height: 150))
            
            // Draw paths
            UIColor.black.setStroke()
            for path in paths {
                let bezierPath = UIBezierPath()
                bezierPath.lineWidth = path.lineWidth
                
                if !path.points.isEmpty {
                    bezierPath.move(to: path.points[0])
                    for point in path.points.dropFirst() {
                        bezierPath.addLine(to: point)
                    }
                    bezierPath.stroke()
                }
            }
        }
    }
}

// MARK: - Signature Preview View
struct SignaturePreviewView: View {
    let signatureData: SignatureData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Digital Signature")
                .font(.caption)
                .foregroundColor(.gray)
            
            if let uiImage = UIImage(data: signatureData.signatureImageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 60)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: .black.opacity(0.1), radius: 3, y: 1)
            }
            
            Text("Signed on \(signatureData.timestamp.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(.white.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
    }
}

struct SignatureView_Previews: PreviewProvider {
    static var previews: some View {
        SignatureView(isPresented: .constant(true)) { _ in
            print("Signature saved")
        }
    }
}