import SwiftUI
import UIKit

/// Custom view for signature capture using a drawing pad
struct SignaturePadView: View {
    @State private var currentPath = Path()
    @State private var paths: [Path] = []
    @State private var lineWidth: CGFloat = 3.0
    @State private var strokeColor: Color = .black
    @State private var showingClearAlert = false
    @State private var showingPreview = false
    @State private var capturedImage: UIImage?
    
    let onSignatureComplete: (UIImage?) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Button("Cancel") {
                    onCancel()
                }
                .foregroundColor(.red)
                
                Spacer()
                
                Text("Your Signature")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Done") {
                    captureSignature()
                }
                .foregroundColor(.blue)
                .disabled(paths.isEmpty && currentPath.isEmpty)
            }
            .padding()
            
            // Instructions
            Text("Please sign below using your finger or Apple Pencil")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Signature Canvas
            ZStack {
                Rectangle()
                    .fill(Color.white)
                    .border(Color.gray.opacity(0.5), width: 2)
                    .cornerRadius(8)
                
                Canvas { context, size in
                    // Draw completed paths
                    for path in paths {
                        context.stroke(path, with: .color(strokeColor), lineWidth: lineWidth)
                    }
                    
                    // Draw current path
                    if !currentPath.isEmpty {
                        context.stroke(currentPath, with: .color(strokeColor), lineWidth: lineWidth)
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let point = value.location
                            if currentPath.isEmpty {
                                currentPath.move(to: point)
                            } else {
                                currentPath.addLine(to: point)
                            }
                        }
                        .onEnded { _ in
                            paths.append(currentPath)
                            currentPath = Path()
                        }
                )
                
                // Placeholder text when empty
                if paths.isEmpty && currentPath.isEmpty {
                    VStack {
                        Image(systemName: "signature")
                            .font(.system(size: 40))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text("Sign here")
                            .font(.title3)
                            .foregroundColor(.gray.opacity(0.7))
                    }
                }
            }
            .frame(height: 200)
            .padding()
            
            // Controls
            VStack(spacing: 15) {
                // Line width control
                HStack {
                    Text("Line Width:")
                        .font(.subheadline)
                    
                    Slider(value: $lineWidth, in: 1...8, step: 1)
                        .frame(maxWidth: 150)
                    
                    Text("\(Int(lineWidth))")
                        .font(.caption)
                        .frame(width: 20)
                }
                
                // Color selection
                HStack {
                    Text("Color:")
                        .font(.subheadline)
                    
                    HStack(spacing: 10) {
                        ForEach([Color.black, Color.blue, Color.red, Color.green], id: \.self) { color in
                            Circle()
                                .fill(color)
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(strokeColor == color ? Color.primary : Color.clear, lineWidth: 3)
                                )
                                .onTapGesture {
                                    strokeColor = color
                                }
                        }
                    }
                }
                
                // Action buttons
                HStack(spacing: 20) {
                    Button(action: {
                        showingClearAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Clear")
                        }
                        .foregroundColor(.red)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .disabled(paths.isEmpty && currentPath.isEmpty)
                    
                    Button(action: undoLastStroke) {
                        HStack {
                            Image(systemName: "arrow.uturn.backward")
                            Text("Undo")
                        }
                        .foregroundColor(.orange)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .disabled(paths.isEmpty)
                    
                    Button(action: {
                        showingPreview = true
                        captureSignature()
                    }) {
                        HStack {
                            Image(systemName: "eye")
                            Text("Preview")
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .disabled(paths.isEmpty && currentPath.isEmpty)
                }
            }
            .padding()
            
            Spacer()
        }
        .alert("Clear Signature", isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                clearSignature()
            }
        } message: {
            Text("Are you sure you want to clear your signature? This action cannot be undone.")
        }
        .sheet(isPresented: $showingPreview) {
            SignaturePreviewView(
                signatureImage: capturedImage,
                onConfirm: {
                    onSignatureComplete(capturedImage)
                },
                onEdit: {
                    showingPreview = false
                }
            )
        }
    }
    
    // MARK: - Helper Methods
    private func clearSignature() {
        paths.removeAll()
        currentPath = Path()
    }
    
    private func undoLastStroke() {
        if !paths.isEmpty {
            paths.removeLast()
        }
    }
    
    private func captureSignature() {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 300, height: 150))
        capturedImage = renderer.image { context in
            let cgContext = context.cgContext
            
            // White background
            cgContext.setFillColor(UIColor.white.cgColor)
            cgContext.fill(CGRect(origin: .zero, size: CGSize(width: 300, height: 150)))
            
            // Draw all paths
            cgContext.setStrokeColor(UIColor(strokeColor).cgColor)
            cgContext.setLineWidth(lineWidth)
            cgContext.setLineCap(.round)
            cgContext.setLineJoin(.round)
            
            for path in paths {
                if let cgPath = path.cgPath as? CGPath {
                    cgContext.addPath(cgPath)
                    cgContext.strokePath()
                }
            }
            
            if !currentPath.isEmpty, let cgPath = currentPath.cgPath as? CGPath {
                cgContext.addPath(cgPath)
                cgContext.strokePath()
            }
        }
    }
    
    private var signatureCanvas: some View {
        Canvas { context, size in
            // White background
            context.fill(Rectangle().path(in: CGRect(origin: .zero, size: size)), with: .color(.white))
            
            // Draw all paths
            for path in paths {
                context.stroke(path, with: .color(strokeColor), lineWidth: lineWidth)
            }
            
            if !currentPath.isEmpty {
                context.stroke(currentPath, with: .color(strokeColor), lineWidth: lineWidth)
            }
        }
        .frame(width: 300, height: 150)
    }
}

// MARK: - Preview
struct SignaturePadView_Previews: PreviewProvider {
    static var previews: some View {
        SignaturePadView(
            onSignatureComplete: { image in
                print("Signature completed with image: \(image != nil)")
            },
            onCancel: {
                print("Signature cancelled")
            }
        )
    }
}