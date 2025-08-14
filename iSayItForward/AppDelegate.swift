import UIKit
import Firebase

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Initialize Firebase directly - no reference to SafeFirebaseProvider
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            print("Firebase configured in AppDelegate")
        }
        return true
    }
}
