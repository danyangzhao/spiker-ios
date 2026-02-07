import Foundation

// MARK: - Notification Service
/// Handles API calls related to push notifications.
/// This communicates with your backend to register/unregister device tokens.
///
/// Your backend needs these endpoints:
///   POST   /api/notifications/register   — saves a device token
///   DELETE /api/notifications/register   — removes a device token
struct NotificationService {
    private let client = APIClient.shared

    /// POST /api/notifications/register - Register a device token with the backend.
    /// The backend stores this token so it can send push notifications to this device.
    ///
    /// Request body: { "token": "abc123...", "platform": "ios" }
    func registerDeviceToken(_ token: String) async throws {
        let _: [String: String] = try await client.post(
            "/api/notifications/register",
            body: [
                "token": token,
                "platform": "ios"
            ]
        )
    }

    /// DELETE /api/notifications/register - Unregister a device token.
    /// Call this when the user logs out or disables notifications,
    /// so the backend stops sending push notifications to this device.
    func unregisterDeviceToken(_ token: String) async throws {
        // We use a POST with an "unregister" action since our APIClient
        // doesn't support DELETE with a body
        let _: [String: String] = try await client.post(
            "/api/notifications/unregister",
            body: ["token": token]
        )
    }
}
