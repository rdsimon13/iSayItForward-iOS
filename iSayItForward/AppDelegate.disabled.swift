import UIKit
import FirebaseCore
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

/// UIKit delegate used by the SwiftUI lifecycle.
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        // Configure Firebase once, as early as possible.
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        return true
    }

    // Keep only if you use Google Sign-In.
    @available(iOS 9.0, *)
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        #if canImport(GoogleSignIn)
        return GIDSignIn.sharedInstance.handle(url)
        #else
        return false
        #endif
    }
}
