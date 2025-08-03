import SwiftUI

// MARK: - Error Handling Utilities
struct ErrorBoundary<Content: View>: View {
    let content: () -> Content
    @State private var hasError = false
    @State private var errorMessage = ""
    
    var body: some View {
        Group {
            if hasError {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    
                    Text("Something went wrong")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(errorMessage)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Retry") {
                        hasError = false
                        errorMessage = ""
                    }
                    .buttonStyle(SecondaryActionButtonStyle())
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 4)
                .padding()
            } else {
                content()
                    .onAppear {
                        print("✅ ErrorBoundary: Content loaded successfully")
                    }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("AppError"))) { notification in
            if let error = notification.object as? String {
                errorMessage = error
                hasError = true
                print("❌ ErrorBoundary: Error caught - \(error)")
            }
        }
    }
}

// MARK: - Global Error Reporter
struct AppErrorReporter {
    static func report(_ error: String) {
        print("❌ AppError: \(error)")
        NotificationCenter.default.post(name: .init("AppError"), object: error)
    }
}

// MARK: - Safe Image View
struct SafeImageView: View {
    let imageName: String
    let width: CGFloat
    let height: CGFloat
    let fallbackIcon: String
    
    init(_ imageName: String, width: CGFloat = 50, height: CGFloat = 50, fallbackIcon: String = "photo") {
        self.imageName = imageName
        self.width = width
        self.height = height
        self.fallbackIcon = fallbackIcon
    }
    
    var body: some View {
        Group {
            if let _ = UIImage(named: imageName) {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: width, height: height)
            } else {
                Image(systemName: fallbackIcon)
                    .font(.system(size: min(width, height) * 0.6))
                    .foregroundColor(Color.brandDarkBlue.opacity(0.7))
                    .frame(width: width, height: height)
                    .onAppear {
                        AppErrorReporter.report("Missing image asset: \(imageName)")
                    }
            }
        }
    }
}