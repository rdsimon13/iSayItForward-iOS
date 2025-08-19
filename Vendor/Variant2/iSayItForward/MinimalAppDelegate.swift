import UIKit
import Firebase

class MinimalAppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Configure Firebase ONCE, at the earliest possible moment
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            print("✅ Firebase configured FIRST and ONLY in MinimalAppDelegate")
        }
        return true
    }
}
