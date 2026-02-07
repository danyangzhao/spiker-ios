import SwiftUI
import UserNotifications

// MARK: - App Delegate
/// The AppDelegate handles system-level events that SwiftUI can't handle directly.
/// For push notifications, iOS sends the device token through the AppDelegate.
class AppDelegate: NSObject, UIApplicationDelegate {

    /// Called when the app successfully registers with Apple Push Notification service (APNs).
    /// APNs gives us a device token (a unique ID for sending notifications to this device).
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        NotificationManager.shared.handleDeviceToken(deviceToken)
    }

    /// Called if registration with APNs fails (e.g., no internet, simulator, etc.).
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        NotificationManager.shared.handleRegistrationError(error)
    }
}

// MARK: - App Entry Point
@main
struct SpikersApp: App {
    // Connect the AppDelegate so iOS can send us push notification events
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .task {
                    // When the app launches, set up notifications:

                    // 1. Set the NotificationManager as the delegate so it can
                    //    handle notifications arriving while the app is open
                    UNUserNotificationCenter.current().delegate = NotificationManager.shared

                    // 2. Check if we already have permission (from a previous launch)
                    await NotificationManager.shared.checkPermissionStatus()

                    // 3. If we don't have permission yet, request it
                    if !NotificationManager.shared.isPermissionGranted {
                        await NotificationManager.shared.requestPermission()
                    }
                }
        }
    }
}
