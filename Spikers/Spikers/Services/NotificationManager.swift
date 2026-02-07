import Foundation
import UserNotifications
import UIKit

// MARK: - Notification Manager
/// Manages push notification permissions, device token registration,
/// and handling of incoming notifications.
///
/// How push notifications work:
/// 1. The app asks the user for permission to send notifications
/// 2. If granted, the app registers with Apple Push Notification service (APNs)
/// 3. APNs gives us a unique "device token" — like a mailing address for this device
/// 4. We send that token to our backend so it knows where to send notifications
/// 5. When a new session is created, the backend sends a push to all registered tokens
@Observable
class NotificationManager: NSObject {

    // MARK: - Properties

    /// Whether the user has granted notification permissions
    var isPermissionGranted = false

    /// The device token string (set after successful APNs registration)
    var deviceToken: String?

    /// Any error message from the notification setup process
    var errorMessage: String?

    /// Singleton instance so it's accessible from anywhere
    static let shared = NotificationManager()

    private let notificationService = NotificationService()

    // MARK: - Init

    private override init() {
        super.init()
    }

    // MARK: - Request Permission

    /// Ask the user for permission to show notifications.
    /// This will display the system "Allow Notifications?" popup.
    func requestPermission() async {
        do {
            // Request permission for alerts (banners), sounds, and badge numbers
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])

            // Update our state on the main thread (since UI depends on this)
            await MainActor.run {
                self.isPermissionGranted = granted
            }

            if granted {
                // If permission was granted, register with APNs to get a device token
                await registerForRemoteNotifications()
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to request notification permission: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Check Current Permission Status

    /// Check if we already have notification permissions (e.g., on app relaunch).
    func checkPermissionStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()

        await MainActor.run {
            self.isPermissionGranted = settings.authorizationStatus == .authorized
        }

        // If already authorized, make sure we're registered for remote notifications
        if settings.authorizationStatus == .authorized {
            await registerForRemoteNotifications()
        }
    }

    // MARK: - Register for Remote Notifications

    /// Tell iOS we want to receive remote (push) notifications.
    /// This triggers the AppDelegate's `didRegisterForRemoteNotificationsWithDeviceToken` method.
    @MainActor
    private func registerForRemoteNotifications() async {
        UIApplication.shared.registerForRemoteNotifications()
    }

    // MARK: - Handle Device Token

    /// Called by the AppDelegate when APNs gives us a device token.
    /// We convert it to a string and send it to our backend.
    func handleDeviceToken(_ tokenData: Data) {
        // Convert the raw token data to a hex string
        // (APNs gives us raw bytes, but we need a string to send to our server)
        let tokenString = tokenData.map { String(format: "%02x", $0) }.joined()

        Task { @MainActor in
            self.deviceToken = tokenString
        }

        print("📱 Device token: \(tokenString)")

        // Send the token to our backend so it can send us push notifications
        Task {
            await sendTokenToBackend(tokenString)
        }
    }

    /// Called by the AppDelegate if APNs registration fails.
    func handleRegistrationError(_ error: Error) {
        Task { @MainActor in
            self.errorMessage = "Push notification registration failed: \(error.localizedDescription)"
        }
        print("❌ Push registration error: \(error.localizedDescription)")
    }

    // MARK: - Send Token to Backend

    /// Send the device token to our backend API so it can send us notifications later.
    private func sendTokenToBackend(_ token: String) async {
        do {
            try await notificationService.registerDeviceToken(token)
            print("✅ Device token registered with backend")
        } catch {
            print("❌ Failed to register token with backend: \(error.localizedDescription)")
            // We don't show this error to the user — it will retry next app launch
        }
    }

    // MARK: - Handle Incoming Notification

    /// Process a notification that was received while the app is in the foreground,
    /// or when the user taps a notification to open the app.
    func handleNotification(_ userInfo: [AnyHashable: Any]) {
        // The notification payload from the server might include a session ID
        // so we can navigate the user to that session
        if let sessionId = userInfo["sessionId"] as? String {
            print("🔔 Notification for session: \(sessionId)")
            // Post a notification so views can react (e.g., navigate to the session)
            NotificationCenter.default.post(
                name: .didReceiveSessionNotification,
                object: nil,
                userInfo: ["sessionId": sessionId]
            )
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
/// This extension handles what happens when a notification arrives
/// while the app is in the foreground, and when the user taps a notification.
extension NotificationManager: UNUserNotificationCenterDelegate {

    /// Called when a notification arrives while the app is open (in the foreground).
    /// By default, notifications don't show when the app is in the foreground,
    /// so we need to tell the system to show them anyway.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show the notification as a banner with sound, even while the app is open
        completionHandler([.banner, .sound, .badge])
    }

    /// Called when the user taps on a notification (either from lock screen or notification center).
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        handleNotification(userInfo)
        completionHandler()
    }
}

// MARK: - Notification Name Extension
/// Custom notification name for when we receive a session-related push notification.
/// This lets any view in the app listen for and react to session notifications.
extension Notification.Name {
    static let didReceiveSessionNotification = Notification.Name("didReceiveSessionNotification")
}
