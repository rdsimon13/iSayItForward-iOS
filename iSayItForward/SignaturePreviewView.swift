import SwiftUI

/// View for displaying saved signatures with preview and management options
struct SignaturePreviewView: View {
    let signatureImage: UIImage?
    let onConfirm: () -> Void
    let onEdit: () -> Void
    
    @State private var showingDetails = false
    @State private var rotationAngle: Double = 0
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                Text("Signature Preview")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding()
                
                // Preview Area
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 250)
                    
                    if let image = signatureImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 200)
                            .scaleEffect(scale)
                            .rotationEffect(.degrees(rotationAngle))
                            .padding()
                    } else {
                        VStack {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 40))
                                .foregroundColor(.orange)
                            
                            Text("No signature to preview")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                
                // Signature details card
                if signatureImage != nil {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            
                            Text("Signature Details")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button(action: {
                                showingDetails.toggle()
                            }) {
                                Image(systemName: showingDetails ? "chevron.up" : "chevron.down")
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        if showingDetails {
                            VStack(alignment: .leading, spacing: 8) {
                                DetailRow(title: "Created", value: formatDate(Date()))
                                DetailRow(title: "Style", value: "Handwritten")
                                DetailRow(title: "Format", value: "PNG Image")
                                DetailRow(title: "Quality", value: "High Resolution")
                                
                                if let image = signatureImage {
                                    DetailRow(title: "Size", value: "\(Int(image.size.width)) × \(Int(image.size.height)) pixels")
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                // Preview controls
                if signatureImage != nil {
                    VStack(spacing: 15) {
                        Text("Preview Controls")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 30) {
                            // Scale control
                            VStack {
                                Image(systemName: "magnifyingglass")
                                    .font(.title3)
                                
                                HStack {
                                    Button(action: { scale = max(0.5, scale - 0.1) }) {
                                        Image(systemName: "minus.circle")
                                    }
                                    
                                    Text("\(Int(scale * 100))%")
                                        .font(.caption)
                                        .frame(width: 40)
                                    
                                    Button(action: { scale = min(2.0, scale + 0.1) }) {
                                        Image(systemName: "plus.circle")
                                    }
                                }
                            }
                            
                            // Rotation control
                            VStack {
                                Image(systemName: "rotate.right")
                                    .font(.title3)
                                
                                HStack {
                                    Button(action: { rotationAngle -= 15 }) {
                                        Image(systemName: "rotate.left")
                                    }
                                    
                                    Text("\(Int(rotationAngle))°")
                                        .font(.caption)
                                        .frame(width: 40)
                                    
                                    Button(action: { rotationAngle += 15 }) {
                                        Image(systemName: "rotate.right")
                                    }
                                }
                            }
                            
                            // Reset control
                            VStack {
                                Image(systemName: "arrow.clockwise")
                                    .font(.title3)
                                
                                Button("Reset") {
                                    scale = 1.0
                                    rotationAngle = 0
                                }
                                .font(.caption)
                            }
                        }
                        .foregroundColor(.blue)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 15) {
                    Button(action: onEdit) {
                        HStack {
                            Image(systemName: "pencil")
                            Text("Edit Signature")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .foregroundColor(.orange)
                        .cornerRadius(10)
                    }
                    
                    Button(action: onConfirm) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Use This Signature")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(signatureImage != nil ? Color.blue : Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(signatureImage == nil)
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Helper Methods
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views
struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Preview
struct SignaturePreviewView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a sample signature image for preview
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 200, height: 100))
        let sampleImage = renderer.image { context in
            context.cgContext.setStrokeColor(UIColor.black.cgColor)
            context.cgContext.setLineWidth(3.0)
            context.cgContext.move(to: CGPoint(x: 20, y: 50))
            context.cgContext.addLine(to: CGPoint(x: 180, y: 50))
            context.cgContext.strokePath()
        }
        
        SignaturePreviewView(
            signatureImage: sampleImage,
            onConfirm: {
                print("Signature confirmed")
            },
            onEdit: {
                print("Edit signature")
            }
        )
    }
}