import UIKit
import FirebaseCore
import FirebaseFirestore
import GoogleSignIn
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {

    // MARK: - App Launch
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {

        // ✅ Initialize Firebase once here (only location needed)
        FirebaseApp.configure()
        print("✅ Firebase configured successfully via AppDelegate.")

        // 🔍 Test Firestore connectivity
        let db = Firestore.firestore()
        db.collection("testConnection").addDocument(data: ["timestamp": Timestamp()]) { error in
            if let error = error {
                print("❌ Firestore write test failed: \(error.localizedDescription)")
            } else {
                print("✅ Firestore test document created successfully.")
            }
        }

        // Request push notification permission
        requestNotificationPermissions()
        return true
    }

    // MARK: - Handle Google Sign-In Redirect
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }

    // MARK: - Push Notification Permissions
    private func requestNotificationPermissions() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("❌ Notification permission error: \(error.localizedDescription)")
            }
            DispatchQueue.main.async {
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                } else {
                    print("⚠️ Notifications permission not granted.")
                }
            }
        }
    }

    // MARK: - Remote Notification Registration
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("✅ Registered for remote notifications. Device token: \(tokenString)")
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("❌ Failed to register for remote notifications: \(error.localizedDescription)")
    }
}

// MARK: - Helper Extension
extension UIApplication {
    var rootController: UIViewController? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?.rootViewController
    }
}
