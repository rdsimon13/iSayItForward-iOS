import FirebaseCore
import GoogleSignIn
import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    
    private let notificationService = NotificationService.shared
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        
        // Configure notification service
        setupNotifications(application)
        
        return true
    }

    // Google Sign-In redirect handler
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
    
    // MARK: - Notification Setup
    private func setupNotifications(_ application: UIApplication) {
        // Request notification permissions
        notificationService.registerForPushNotifications()
        
        // Set notification delegate
        UNUserNotificationCenter.current().delegate = notificationService
    }
    
    // MARK: - Push Notification Registration
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        notificationService.didRegisterForRemoteNotifications(withDeviceToken: deviceToken)
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        notificationService.didFailToRegisterForRemoteNotifications(withError: error)
    }
    
    // MARK: - App Lifecycle for Notifications
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Clear badge when app becomes active
        notificationService.clearBadge()
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Update badge count when entering background
        // This ensures the badge reflects the current unread count
        application.applicationIconBadgeNumber = notificationService.unreadCount
    }
}
