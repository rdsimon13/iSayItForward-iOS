import FirebaseCore
import GoogleSignIn
import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        
        // Set up notification center delegate
        UNUserNotificationCenter.current().delegate = NotificationService.shared
        
        return true
    }

    // Google Sign-In redirect handler
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        // Handle deep links for QR codes
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           components.scheme == "isayitforward" {
            Task {
                let result = await QRCodeService.shared.handleDeepLink(url)
                // Handle the deep link result
                switch result {
                case .sif(let sif), .share(let sif):
                    NotificationCenter.default.post(name: .navigateToSIF, object: sif.id)
                case .error(let error):
                    print("Deep link error: \(error)")
                case .unsupported:
                    print("Unsupported deep link: \(url)")
                }
            }
            return true
        }
        
        return GIDSignIn.sharedInstance.handle(url)
    }
    
    // MARK: - Push Notifications
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // Convert device token to string and store in Firestore if needed
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        
        // Store the token for this user in Firestore for future push notifications
        // This would typically be done in a user management service
        print("Device token: \(token)")
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register for remote notifications: \(error)")
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Clear badge when app becomes active
        NotificationService.shared.clearBadge()
    }
}
