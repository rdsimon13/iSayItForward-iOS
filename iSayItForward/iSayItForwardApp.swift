import SwiftUI
import FirebaseCore

// Keep the tiny delegate so GoogleUtilities/AppDelegateSwizzler is satisfied.
final class BasicAppDelegate: NSObject, UIApplicationDelegate {}

@main
struct iSayItForwardApp: App {
    @UIApplicationDelegateAdaptor(BasicAppDelegate.self) var basicDelegate
    @StateObject private var authState = AuthState()

    init() {
        if FirebaseApp.app() == nil { FirebaseApp.configure() }
        print("✅ Firebase configured? \(FirebaseApp.app() != nil)")
    }

    var body: some Scene {
        WindowGroup {
            RootHost()
                .environmentObject(authState)
        }
    }
}

/// A safe wrapper that shows your real root when it successfully appears,
/// but gives you clear diagnostics (and a fallback) if it doesn’t.
struct RootHost: View {
    @EnvironmentObject var authState: AuthState

    @State private var didRenderGettingStarted = false
    @State private var timedOutFallback = false

    var body: some View {
        ZStack {
            // Underlay so you never see pure white if the child view fails early
            Color.black.opacity(0.02).ignoresSafeArea()

            if timedOutFallback {
                // If GettingStartedView never renders, show a known-safe screen
                FallbackHome()
                    .transition(.opacity)
            } else {
                // Your intended root
                GettingStartedView()
                    .onAppear {
                        didRenderGettingStarted = true
                        print("🟢 GettingStartedView didAppear")
                    }
                    .transition(.opacity)
            }

            // Visible overlay while we wait
            if !didRenderGettingStarted && !timedOutFallback {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Loading UI…").font(.callout)
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                .shadow(radius: 6)
            }
        }
        // If the root hasn't rendered after 2s, assume it's blocked by a crash/missing env object
        .task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if !didRenderGettingStarted {
                print("⚠️ GettingStartedView did not render in time — showing fallback.")
                timedOutFallback = true
            }
        }
    }
}

/// A minimal, known-safe screen to prove the app UI still renders
struct FallbackHome: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [.blue.opacity(0.9), .cyan], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "house.fill").font(.system(size: 42)).foregroundStyle(.white)
                Text("Fallback Home")
                    .font(.title.bold()).foregroundStyle(.white)
                Text("Your GettingStartedView didn't render. See Xcode console for hints.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding()
        }
        .onAppear { print("🟢 FallbackHome appeared") }
    }
}
