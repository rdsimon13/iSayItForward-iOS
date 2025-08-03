import SwiftUI
import FirebaseAuth
import FirebaseCore

struct AppInitializationView: View {
    @EnvironmentObject var authState: AuthState
    @State private var isInitializing = true
    @State private var initializationError: String?
    @State private var showDebugInfo = false
    
    var body: some View {
        ZStack {
            Color.mainAppGradient.ignoresSafeArea()
            
            if isInitializing {
                LoadingView()
            } else if let error = initializationError {
                ErrorView(error: error) {
                    retryInitialization()
                }
            } else {
                // Initialization successful, show main app content
                MainAppView()
                    .environmentObject(authState)
            }
        }
        .onAppear {
            initializeApp()
        }
        .onTapGesture(count: 5) {
            // Debug: 5 taps to show debug info
            showDebugInfo.toggle()
        }
        .sheet(isPresented: $showDebugInfo) {
            DebugInfoView()
        }
    }
    
    private func initializeApp() {
        print("🚀 [AppInit] Starting app initialization...")
        
        // Simulate initialization time and check Firebase
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            do {
                // Verify Firebase is configured
                guard FirebaseApp.app() != nil else {
                    throw AppInitializationError.firebaseNotConfigured
                }
                
                // Check if Auth is available
                _ = Auth.auth()
                
                print("✅ [AppInit] App initialization successful")
                withAnimation(.easeInOut(duration: 0.5)) {
                    isInitializing = false
                }
            } catch {
                print("❌ [AppInit] Initialization failed: \(error)")
                initializationError = error.localizedDescription
                isInitializing = false
            }
        }
    }
    
    private func retryInitialization() {
        initializationError = nil
        isInitializing = true
        initializeApp()
    }
}

// MARK: - Loading View
private struct LoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 24) {
            Image("isifLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 96, height: 96)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .animation(
                    Animation.easeInOut(duration: 1.0)
                        .repeatForever(autoreverses: true),
                    value: isAnimating
                )
            
            Text("iSayItForward")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(Color.brandDarkBlue)
            
            Text("Loading...")
                .font(.headline)
                .foregroundColor(.secondary)
            
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(CircularProgressViewStyle(tint: Color.brandDarkBlue))
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Error View
private struct ErrorView: View {
    let error: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.red)
            
            Text("Initialization Failed")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(Color.brandDarkBlue)
            
            Text(error)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button("Retry") {
                onRetry()
            }
            .buttonStyle(PrimaryActionButtonStyle())
        }
    }
}

// MARK: - Debug Info View
private struct DebugInfoView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Debug Information")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Group {
                    InfoRow(label: "App Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
                    InfoRow(label: "Build Number", value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown")
                    InfoRow(label: "iOS Version", value: UIDevice.current.systemVersion)
                    InfoRow(label: "Device Model", value: UIDevice.current.model)
                    InfoRow(label: "Firebase App", value: FirebaseApp.app() != nil ? "Configured" : "Not Configured")
                    InfoRow(label: "Auth State", value: Auth.auth().currentUser != nil ? "Authenticated" : "Not Authenticated")
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Debug")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

private struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .fontWeight(.medium)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Main App View
private struct MainAppView: View {
    var body: some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            iPadMainView()
        } else {
            WelcomeView()
        }
    }
}

// MARK: - App Initialization Errors
enum AppInitializationError: LocalizedError {
    case firebaseNotConfigured
    
    var errorDescription: String? {
        switch self {
        case .firebaseNotConfigured:
            return "Firebase is not properly configured. Please check your GoogleService-Info.plist file."
        }
    }
}