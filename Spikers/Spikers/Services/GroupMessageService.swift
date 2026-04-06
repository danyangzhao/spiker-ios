import Foundation

// MARK: - Group Message Service
struct GroupMessageService {
    private let client = APIClient.shared

    /// GET /api/groups/[groupId]/messages
    func fetchMessages(groupId: String) async throws -> GroupMessagesResponse {
        try await client.get("/api/groups/\(groupId)/messages")
    }

    /// POST /api/groups/[groupId]/messages
    func createMessage(groupId: String, title: String, body: String, authorId: String) async throws -> GroupMessageCreateResponse {
        try await client.post(
            "/api/groups/\(groupId)/messages",
            body: [
                "title": title,
                "messageBody": body,
                "authorId": authorId
            ]
        )
    }

    /// PUT /api/groups/[groupId]/messages/[messageId]
    func updateMessage(groupId: String, messageId: String, title: String, body: String) async throws -> GroupMessageUpdateResponse {
        try await client.put(
            "/api/groups/\(groupId)/messages/\(messageId)",
            body: [
                "title": title,
                "messageBody": body
            ]
        )
    }
}
