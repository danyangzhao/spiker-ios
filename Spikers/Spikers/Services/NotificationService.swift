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

    /// Register a device token with the backend, associated with the current group.
    func registerDeviceToken(_ token: String) async throws {
        var body: [String: Any] = [
            "token": token,
            "platform": "ios"
        ]
        if let groupId = GroupManager.shared.currentGroupId {
            body["groupId"] = groupId
        }
        let _: [String: String] = try await client.post(
            "/api/notifications/register",
            body: body
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
